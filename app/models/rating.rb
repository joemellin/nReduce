class Rating < ActiveRecord::Base
  attr_accessible :explanation, :feedback, :interested, :investor_id, :startup_id
end
