class Instrument < ActiveRecord::Base
  has_many :measurements
  belongs_to :startup
end
