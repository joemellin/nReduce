class Rating < ActiveRecord::Base
  belongs_to :user
  belongs_to :startup
  has_many :awesomes, :as => :awsm, :dependent => :destroy

  attr_accessible :explanation, :feedback, :interested, :startup_id, :contact_in, :weakest_element, :connected

  FEEDBACK_OPTIONS = [:team, :idea, :traction, :market]

  bitmask :feedback, :as => Rating::FEEDBACK_OPTIONS

  validates_presence_of :startup_id
  validates_presence_of :user_id
  validates_presence_of :contact_in
  validates_presence_of :weakest_element
  validate :relationship_exists
  validate :investor_can_connect

  before_validation :set_interested_from_contact_in
  before_create :change_suggested_relationship_state

  scope :ordered, order('created_at DESC')

  CONTACT_IN_NEVER = 1
  CONTACT_IN_NOW = 5

  def self.weakest_element_labels
    {
      1 => 'Team',
      2 => 'Market',
      3 => 'Traction',
      4 => 'Product',
      5 => 'Other'
    }
  end

  def self.contact_in_labels
    { 1 => ['Not a fit', "Don't show me this startup again"],
      2 => ['6 months', 'Show me again in 6 months and I might be interested'],
      3 => ['3 months', 'Show me again in 3 months and I might be interested'],
      4 => ['1 month', 'Show me again in 1 month and I might be interested'],
      5 => ['Now', 'Please introduce me today']
    }
  end

  def contact_now?
    self.contact_in == CONTACT_IN_NOW
  end

  def contact_never?
    self.contact_in == CONTACT_IN_NEVER
  end

  def contact_in_desc
    return nil if self.contact_in.blank?
    Rating.contact_in_labels[self.contact_in].first unless Rating.contact_in_labels[self.contact_in].blank?
  end

  def weakest_element_desc
    return nil if self.weakest_element.blank?
    Rating.weakest_element_labels[self.weakest_element] unless Rating.weakest_element_labels[self.weakest_element].blank?
  end

  # Takes an array of ratings and returns an array for weakest element, eg: [['Traction', 5], ['Market', 4]] - used in charts
  def self.weakest_element_arr_from_ratings(ratings)
    we = {}
    # Set it up so all values are represented
    Rating.weakest_element_labels.each{|id, label| we[id] = 0 }
    ratings.map{|r| we[r.weakest_element] += 1 }
    ret = []
    we.each do |id, num|
      ret << [Rating.weakest_element_labels[id], num]
    end
    ret
  end

  # For use in pie chart
  def self.weakest_element_pct_arr_from_ratings(ratings)
    we = {}
    ratings.map{|r| we[r.weakest_element] ||= 0; we[r.weakest_element] += 1 }
    ret = {}
    total = we.inject(0.0){|r,e| r + e.last }
    we.each do |id, num|
      ret[Rating.weakest_element_labels[id]] = ((num / total) * 100).round(2)
    end
    ret.sort{|a,b| a.last <=> b.last }.reverse
  end

  # Takes an array of ratings and returns an array for contact in time (format same as weakest element) - used in charts
  def self.contact_in_arr_from_ratings(ratings)
    ci = {}
    Rating.contact_in_labels.each{|id, label| ci[id] = 0 }
    ratings.map{|r| ci[r.contact_in] += 1 }
    ret = []
    ci.each do |id, num|
      ret << [Rating.contact_in_labels[id].first, num]
    end
    ret
  end

  # Finds the relationship that exists between the startup and investor involved in this rating
  def startup_relationship
    Relationship.between(self.user, self.startup)
  end

  protected

  def set_interested_from_contact_in
    return true
    self.interested = true if self.contact_in == CONTACT_IN_NOW
    true
  end

  def investor_can_connect
    if self.interested? # only check if they want to connect
      unless self.user.can_connect_with_startups?
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
