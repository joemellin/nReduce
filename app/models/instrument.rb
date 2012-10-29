class Instrument < ActiveRecord::Base
  has_many :measurements, :dependent => :destroy
  belongs_to :startup

  attr_accessible :name, :startup, :startup_id, :instrument_type_id

  validates_presence_of :startup_id
  validates_presence_of :instrument_type_id
  validate :one_instrument_per_startup

  def self.instrument_types
    {
      1 => ['Weekly Active Users', 'For companies that do not charge their main users (revenue often from ads)', 'Facebook, Codecademy'],
      2 => ['Weekly Revenue', 'For businesses that sell individual products and services', 'Amazon, Rosetta Stone, Pebble'],
      3 => ['Weekly # of Paid Subscribers', 'For subscription businesses', 'Match.com, Netflix, BirchBox'],
      4 => ['Weekly # of Completed Transactions', 'For marketplaces or companies who earn a transaction fee', '99Designs, Uber, eBay'],
      5 => ['Weekly Page Views', 'For online content companies', 'TripAdvisor, PandoDaily']
    }
  end

  def name
    self['name'].blank? && !self.instrument_type_id.blank? ? Instrument.instrument_types[self.instrument_type_id][0] : self['name']
  end

  def description
    Instrument.instrument_types[self.instrument_type_id][1]
  end

  def examples
    Instrument.instrument_types[self.instrument_type_id][2]
  end

  protected

  def one_instrument_per_startup
    if self.new_record?
      self.errors.add(:startup_id, 'already has a metric saved') if self.startup.instruments.count >= 1
    else
      self.errors.add(:startup_id, 'already has a metric saved') if self.startup.instruments.where(['id != ?', self.id]).count >= 1
    end
  end
end
