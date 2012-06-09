class Checkin < ActiveRecord::Base
  belongs_to :startup
  belongs_to :user # the user logged in who created check-in

  attr_accessible :start_focus, :start_why, :start_video_url, :end_video_url, :end_comments, :week_id, :startup_id

  after_validation :check_submitted_completed_times

  validates_presence_of :startup_id
  validates_presence_of :start_focus, :message => "can't be blank"
  validates_presence_of :start_video_url, :message => "can't be blank"
  validates_presence_of :end_video_url, :message => "can't be blank", :if =>  Proc.new {|checkin| checkin.completed? }
  validate :check_video_urls_are_valid

  def submitted?
    !submitted_at.blank?
  end

  def completed?
    !completed_at.blank?
  end

  def self.video_url_is_unique?(url)
    cs = Checkin.where(:start_video_url => url).or(:end_video_url => url)
    return cs.map{|c| c.id }.delete_if{|id| id == self.id }.count > 0
  end

  protected

  def check_video_urls_are_valid
    err = false
    if !start_video_url.blank? and !Youtube.valid_url?(start_video_url)
      self.errors.add(:start_video_url, 'invalid Youtube URL')
      err = true
    end
    if !end_video_url.blank? and !Youtube.valid_url?(end_video_url)
      self.errors.add(:end_video_url, 'invalid Youtube URL')
      err = true
    end
    err
  end

  def check_submitted_completed_times
    if self.errors.blank?
      self.submitted_at = Time.now if !self.submitted? and !start_focus.blank? and !start_video_url.blank?
      self.completed_at = Time.now if self.submitted? and !self.completed? and !end_video_url.blank?
    end
    true
  end
end
