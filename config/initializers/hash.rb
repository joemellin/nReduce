class Hash
  # Pass an array of objects - will return a hash keyed by a method or an attribute
  # Set array to be true to allow multiple objects stored by that key
  def self.by_key(objs = [], attr = nil, method = nil, array = false)
    return {} if objs.blank?
    if !method.blank?
      method = method.to_sym
      objs.inject({}) do |r,e|
        if array
          r[e.send(method)] ||= []
          r[e.send(method)] << e
        else
          r[e.send(method)] = e
        end
        r
      end
    elsif !attr.blank?
      objs.inject({}) do |r,e|
        if array
          r[e[attr]] ||= []
          r[e[attr]] << e
        else
          r[e[attr]] = e
        end
        r
      end
    else
      {}
    end
  end
end
