class DemoDay < ActiveRecord::Base
  has_many :users
  has_many :startups

  attr_accessible :name, :day, :description
end
