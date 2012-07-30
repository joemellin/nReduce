class SlideDeck < ActiveRecord::Base
  attr_accessible :slides, :startup_id, :title
end
