class Measurement < ActiveRecord::Base
  belongs_to :instrument
  has_one :checkin
  has_one :startup, :through => :instrument

  attr_accessible :value, :instrument, :instrument_id, :checkin, :checkin_id, :delta

  scope :ordered_asc, order('created_at ASC')
  scope :ordered, order('created_at DESC')

  before_save :calculate_delta, :if => :value_changed?
  after_create :reset_startup_measurement_cache

  validates_numericality_of :value, :greater_than_or_equal_to => 0

  # When run, will calculate change between each measurement (by instrument) for any that don't have delta recorded
  def self.calculate_delta_for_all_measurements
    ms = Hash.by_key(Measurement.order('created_at ASC').all, :instrument_id, nil, true)
    ms.each do |instrument_id, measurements|
      c = 0
      prev = nil
      measurements.each do |m|
        unless prev.blank?
          m.calculate_delta(prev)
          puts m.delta
          m.save
        end
        c += 1
        prev = m
      end
    end
  end

  def previous_measurement
    Measurement.where(:instrument_id => self.instrument_id).where(['created_at < ?', self.created_at || Time.now]).order('created_at DESC').first
  end

  def calculate_delta(prev = nil)
    begin
      prev ||= self.previous_measurement
      return true if self.value.blank? || prev.blank? || prev.value.blank?
      if prev.value != 0.0
        delta = (((self.value - prev.value) / prev.value) * 100.0).round(2) unless prev.blank?
      end
      delta = 0.0 if delta.nil? || !delta.is_a?(Float)
    rescue
      delta = 0.0
    end
    self.delta = delta
    true
  end

  # for use with charts
  def key
    created_at.strftime('%b %d')
  end

  protected

  def reset_startup_measurement_cache
    self.startup.reset_latest_measurement_cache
  end
end