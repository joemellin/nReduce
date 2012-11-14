class AbTest < ActiveRecord::Base
  has_many :user_actions

  # Checks whether they have seen this test, if so return what version they already saw
  # Returns :a or :b for this session id

  def self.version_for_session_id(ab_test_id, session_id)
    key = "ab_test_#{ab_test_id}"

    # Check if user has already seen this test
    index = Cache.set_index_of(key, session_id)
    
    # Else add item
    if index.nil?
      Cache.set_push(key, session_id)
      # Index is number of items - 1
      index = Cache.set_count(key) - 1
    end

    # And now return a or b depending on number of items
    return (index % 2 == 0) ? :a : :b
  end
end