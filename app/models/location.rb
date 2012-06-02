class Location < ActiveRecord::Base
  has_many :startups
  has_many :authentications

  attr_accessible :name, :order, :venue_name, :venue_url, :venue_description

  validates_presence_of :name
  validates_uniqueness_of :name, :on => :create, :message => "must be unique"

  scope :ordered, ascending(:order)

  def self.select_options
    Location.ordered.map do |location|
      [
        location.name,
        location.id,
      ]
    end
  end
end
