class Measurement < ActiveRecord::Base
  belongs_to :instrument
  has_one :checkin
  has_one :startup, :through => :instrument

  attr_accessible :value, :instrument, :instrument_id, :checkin, :checkin_id

  scope :ordered_asc, order('created_at ASC')
  scope :ordered, order('created_at DESC')

  after_create :reset_startup_measurement_cache

  validates_numericality_of :value, :greater_than_or_equal_to => 0

  protected

  def reset_startup_measurement_cache
    self.startup.reset_latest_measurement_cache
  end
end
