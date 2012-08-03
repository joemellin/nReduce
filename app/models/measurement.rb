class Measurement < ActiveRecord::Base
  belongs_to :instrument
  attr_accessible :startup_id, :value
end
