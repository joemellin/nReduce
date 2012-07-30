class SlideDeck < ActiveRecord::Base
  belongs_to :startup
  
  attr_accessible :slides, :startup_id, :title
  serialize :slides
end
