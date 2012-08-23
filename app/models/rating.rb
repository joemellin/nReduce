class Rating < ActiveRecord::Base
  belongs_to :investor, :class_name => 'User'
  belongs_to :startup

  attr_accessible :explanation, :feedback, :interested, :investor_id, :startup_id, :contact_in, :weakest_element

  FEEDBACK_OPTIONS = [:team, :idea, :traction, :market]

  bitmask :feedback, :as => Rating::FEEDBACK_OPTIONS

  validates_presence_of :startup_id
  validates_presence_of :investor_id
  validates_presence_of :contact_in
  validates_presence_of :weakest_element
  validate :relationship_exists
  validate :investor_can_connect

  before_create :change_suggested_relationship_state

  scope :ordered, order('created_at DESC')

  def self.contact_in_labels
    { 1 => ['Not a fit', "Don't show me this startup again"],
      2 => ['6 months', 'Show me again in 6 months and I might be interested'],
      3 => ['3 months', 'Show me again in 3 months and I might be interested'],
      4 => ['1 month', 'Show me again in 1 month and I might be interested'],
      5 => ['Now', 'Please introduce me today']
    }
  end

  def self.weakest_element_labels
    { 1 => 'Team',
      2 => 'Market',
      3 => 'Traction',
      4 => 'Product',
      5 => 'Other',
    }
  end

  def contact_in_desc
    return nil if self.contact_in.blank?
    Rating.contact_in_labels[self.contact_in].first unless Rating.contact_in_labels[self.contact_in].blank?
  end

  def weakest_element_desc
    return nil if self.weakest_element.blank?
    Rating.weakest_element_labels[self.weakest_element].first unless Rating.weakest_element_labels[self.weakest_element].blank?
  end

  # Takes an array of ratings and returns a hash for weakest element - used in charts
  def self.weakest_element_hash_from_ratings(ratings)
    we = {}
    ratings.map{|r| we[r.weakest_element] ||= 0; we[r.weakest_element] += 1 }
    ret = {}
    we.each do |id, num|
      ret[Rating.weakest_element_labels[id]] = num
    end
    ret
  end

  # Takes an array of ratings and returns a hash for contact in time - used in charts
  def self.contact_in_hash_from_ratings(ratings)
    ci = {}
    ratings.map{|r| ci[r.contact_in] ||= 0; ci[r.contact_in] += 1 }
    ret = {}
    ci.each do |id, num|
      ret[Rating.contact_in_labels[id].first] = num
    end
    ret
  end

  # Finds the relationship that exists between the startup and investor involved in this rating
  def startup_relationship
    Relationship.between(self.investor, self.startup)
  end

  protected

  def investor_can_connect
    if self.interested? # only check if they want to connect
      unless self.investor.can_connect_with_startups?
        self.errors.add(:startup_id, 'you have reached your limit - please upgrade your account to connect to more startups')
        return false
      end
    end
    true
  end

  def relationship_exists
    if self.new_record?
      rel = self.startup_relationship
      if rel.blank? || (!rel.blank? and !rel.suggested?)
        self.errors.add(:startup_id, "has already been rated by you.")
        return false
      end
    end
    true
  end

  # Sets suggested relationship to pending if interested, or passed if they pass
  def change_suggested_relationship_state
    if self.new_record?
      rel = self.startup_relationship
      if self.interested?
        rel.approve! # turns it to pending state
      else
        rel.reject_or_pass! # sets it as passed
      end
    end
    true
  end
end
