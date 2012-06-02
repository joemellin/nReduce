class Batch < ActiveRecord::Base
  has_many :startups

  attr_accessible :name, :subdomain

  validates_uniqueness_of :subdomain, :on => :create, :message => "must be unique"

end
