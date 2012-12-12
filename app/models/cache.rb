require 'json/ext' # faster json parsing https://github.com/flori/json

class Cache
  @@enabled = true

    # Set a cache value - can pass a block where you set the value
    # If cache key isn't a string, cache class will hash it
    # Unless raw is passed, it serializes to JSON
  def self.set(key, value, expires_in = nil, raw = false)
    return true if !@@enabled
    key = Cache.key_for(key)
    value = JSON.generate(value) unless raw
    res = $redis.set(key, value) == 'OK' ? true : false
    #Cache.logger.info "CACHE: #{res ? 'hit' : 'miss'} #{key}"
    $redis.expire(key, expires_in.to_i) if res and !expires_in.blank?
    res
  end

    # Get a cache key
    # Can pass a block that returns the value you'd like to set (like the results of a db query)
  def self.get(key, expires_in = nil, raw = false, &block)
    if !@@enabled
      # If cache is disabled return block
      if block.blank?
        return yield
      else
        return nil
      end
    end
    key = Cache.key_for(key)
    value = $redis.get(key)
    # If key isn't set, and block is passed - set key to return value of block
    if !value.nil?
      #Cache.logger.info "CACHE: get #{key}"
      value = JSON.parse(value) unless value.blank? or raw
    elsif value.nil? and !block.blank?
      #Cache.logger.info "CACHE: set a get for key #{key}"
      value = yield
      return value if value.blank?
      Cache.set(key, value, expires_in.to_i, raw)
    end
    value
  end

    # Deletes a key
  def self.delete(key)
    key = Cache.key_for(key)
    res = $redis.del(key) # returns 1 if was set, 0 if not. ignore results anyway
    #Cache.logger.info "CACHE: delete #{res == 1 ? 'success' : 'failure'} #{key}"
    true
  end

  #
  # Array (lists in redis) manipulation methods
  #

    # Add an item to an array
  def self.arr_push(key, value)
    res = $redis.lpush(key, value)
    #Cache.logger.info "CACHE: arr push with index #{res} to #{key}"
    true
  end

    # return all elements in an array
  def self.arr_get(key)
    key = Cache.key_for(key)
    res = $redis.lrange(key, 0, Cache.arr_count(key))
    #Cache.logger.info "CACHE: arr get for #{key}"
    res
  end

  def self.arr_count(key)
    key = Cache.key_for(key)
    $redis.llen(key)
  end

  # 
  # Sorted set manipulation methods
  #

  # Appends a value to a set
  def self.set_push(key, value)
    key = Cache.key_for(key)
    res = $redis.zadd(key, '1', value)
    res == 1
  end

  # Returns index of value
  def self.set_index_of(key, value)
    key = Cache.key_for(key)
    res = $redis.zrank(key, value)
    res
  end

  # Returns number of values in this set
  def self.set_count(key)
    key = Cache.key_for(key)
    res = $redis.zcard(key)
    res
  end

  # Deletes value from a set
  def self.set_delete(key, value)
    key = Cache.key_for(key)
    res = $redis.zrem(key, value)
    res == 1
  end

  def self.set_delete_by_index(key, index_from, index_to)
    key = Cache.key_for(key)
    res = $redis.zremrangebyrank(key, index_from, index_to)
    res
  end

  #
  # Counters / increment
  #

  def self.incr(key)
    key = Cache.key_for(key)
    $redis.incr(key)
  end

  #
  # Utility methods
  #

  # Hashes objects to a key that can be used for cache set/get
  def self.key_for(*args)
    # if args is an array of items, flatten it
    return args.first if args.size == 1 and args.first.is_a?(String)
    args = args.flatten if args.size == 1 and args.first.is_a?(Array)
    # any args that are active record objects - use classname_id
    args.map{|a| (a.respond_to?(:new_record?)) ? "#{a.class}_#{a.id}" : a.to_s }.join('_').downcase
  end

  def self.enabled?
    @@enabled
  end

  def self.enabled=(enabled)
    @@enabled = enabled
  end

  def self.logger
    ActiveRecord::Base.logger
  end
end