class Measurement < ActiveRecord::Base
  belongs_to :instrument
  has_one :checkin
  attr_accessible :startup_id, :value, :instrument, :instrument_id
end
