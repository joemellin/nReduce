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

  def self.contact_in_labels(extended = false)
    if extended
      { 1 => "Don't show me this startup again",
        2 => 'Show me again in 6 months and I might be interested',
        3 => 'Show me again in 3 months and I might be interested',
        4 => 'Show me again in 1 month and I might be interested',
        5 => 'Please introduce me today'
      }
    else
      { 1 => 'Not a fit',
        2 => '6 months',
        3 => '3 months',
        4 => '1 month',
        5 => 'Now'
      }
    end
  end

  def contact_now?
    self.contact_in == CONTACT_IN_NOW
  end

  def contact_never?
    self.contact_in == CONTACT_IN_NEVER
  end

  def contact_in_desc
    return nil if self.contact_in.blank?
    Rating.contact_in_labels[self.contact_in] unless Rating.contact_in_labels[self.contact_in].blank?
  end

  def weakest_element_desc
    return nil if self.weakest_element.blank?
    Rating.weakest_element_labels[self.weakest_element] unless Rating.weakest_element_labels[self.weakest_element].blank?
  end

  # Takes an array of ratings and returns for column provided, either :contact_in or :weakest_element
  # eg: [['Traction', 5], ['Market', 4]] - used in charts
  def self.chart_data_from_ratings(ratings, column)
    investor_ratings = {}
    mentor_ratings = {}
    labels = Rating.send("#{column}_labels".to_sym)

    # Set it up so all values are represented
    labels.each{|id, label| investor_ratings[id] = 0; mentor_ratings[id] = 0 }

    # Split up ratings between investors and mentors
    ratings.each do |r|
      if r.user.investor?
        investor_ratings[r.send(column)] += 1
      elsif r.user.mentor?
        mentor_ratings[r.send(column)] += 1
      end
    end

    {
      :categories => labels.values, 
      :series =>
        {
          'Investor' => investor_ratings.sort.map{|k,v| v }, 
          'Mentor' => mentor_ratings.sort.map{|k,v| v }
        }
    }
  end

  # Finds the relationship that exists between the startup and investor involved in this rating
  def startup_relationship
    Relationship.between(self.user, self.startup)
  end

  protected

  def set_interested_from_contact_in
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
