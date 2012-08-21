class Measurement < ActiveRecord::Base
  belongs_to :instrument
  has_one :checkin
  has_one :startup, :through => :instrument

  attr_accessible :value, :instrument, :instrument_id, :checkin, :checkin_id

  scope :ordered_asc, order('created_at ASC')

  validates_numericality_of :value, :greater_than_or_equal_to => 0
end
