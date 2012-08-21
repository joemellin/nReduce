class Instrument < ActiveRecord::Base
  has_many :measurements
  belongs_to :startup

  attr_accessible :name, :startup, :startup_id

  validates_presence_of :startup_id
  validates_presence_of :name
  validate :one_instrument_per_startup

  protected

  def one_instrument_per_startup
    self.errors.add(:startup_id, 'already has a metric saved') if self.startup.instruments.count >= 1
  end
end
