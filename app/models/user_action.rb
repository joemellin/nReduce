class UserAction < ActiveRecord::Base  
  belongs_to :user
  belongs_to :attachable, :polymorphic => true
  
  attr_accessible :attachable, :ip, :action, :url_path, :browser, :data, :time_taken, :user, :user_id, :created_at

  serialize :data

  scope :ordered, :order => 'created_at DESC'
  
    # Returns hash of all user actions
  def self.actions
    {
      'unknown' => 0,
      # Actions for our site
      'relationships_index' => 1,
      'relationships_create' => 2,
      'relationships_approve' => 3,
      'relationships_reject' => 4,
      'checkins_index' => 5,
      'checkins_show' => 6,
      'checkins_edit' => 7,
      'checkins_update' => 8,
      'checkins_delete' => 9,
      'startups_new' => 10,
      'startups_create' => 11,
      'startups_show' => 12,
      'startups_edit' => 13,
      'startups_update' => 14,
      'startups_onboard' => 15,
      'startups_search' => 16, 
      'registrations_new' => 17,
      'registrations_create' => 18,
      'authentications_create' => 19,
      'authentications_failure' => 20,
      'authentications_destroy' => 21,
      'users_show' => 22,
      'users_edit' => 23,
      'users_update' => 24,
      'users_chat' => 25,
      'comments_create' => 26,
      'comments_edit' => 27,
      'comments_update' => 28,
      'comments_destroy' => 29,
      'pages_mentor' => 30,
      'pages_investor' => 31
    }
  end
  
    # When given an action name (string), this will return the action id for that action name
  def self.id_for(action_name = nil)
    id = self.actions[action_name]
    id.blank? ? self.actions['unknown'] : id
  end
  
  def self.by_action(action_name)
    where(:action => self.id_for(action_name))
  end
  
  def action_name
    UserAction.actions.each{|k,v| return k if v == self.action }
    return !self.site_path.blank? ? self.site_path : '' 
  end
  
  def unknown_action?
    self.action.blank? or self.action == 0
  end
end
