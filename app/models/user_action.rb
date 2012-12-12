class UserAction < ActiveRecord::Base  
  belongs_to :user
  belongs_to :attachable, :polymorphic => true
  belongs_to :ab_test
  
  attr_accessible :attachable, :ip, :action, :url_path, :browser, :data, 
    :time_taken, :user, :user_id, :created_at, :session_id, :ab_test_id, :ab_test_version

  serialize :data, Hash

  # queue to cache, then write when cache reaches 1000 user actions
  @@queue_actions = true

  # Resque queue name
  @queue = :user_actions

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
      'relationships_remove' => 5,
      'checkins_show' => 6,
      'relationships_show' => 7,
      'relationships_suggest' => 8,
      'external_link' => 9,
      'pages_home' => 10,
      'registrations_new' => 11,
      'weekly_classes_show' => 12,
      'checkins_create' => 13,
      'registrations_create' => 14,
      'checkins_first' => 15
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

  def self.weekly_actives
    UserAction.where(:action => UserAction.id_for('relationships_index')).where(['created_at > ?', Time.now - 1.week]).group(:user_id).count.size
  end
  
  def action_name
    UserAction.actions.each{|k,v| return k if v == self.action }
    return !self.site_path.blank? ? self.site_path : '' 
  end
  
  def unknown_action?
    self.action.blank? or self.action == 0
  end

  # overwrite save action to queue to cache
  def save!(*args)
    if self.new_record? and UserAction.queue_actions?
      # Remove attached object if it's a new record, it won't marshal correctly
      self.attachable = nil #if !self.attachable.blank? and self.attachable.new_record?
      # Add to in-memory cache
      Cache.arr_push('user_actions', Marshal.dump(self))
      # Trigger in-memory cache to write to disk
      Resque.enqueue(UserAction) if Cache.arr_count('user_actions') > 500
      true
    else
      super
    end
  end

    # Writes user actions to database
  def self.perform
    # have to call all classes or ruby will complain when unmarshaling
    [
      UserAction.class, 
      Checkin.class,
      Comment.class, 
      User.class, 
      Meeting.class, 
      Invite.class, 
      Authentication.class, 
      Awesome.class, 
      Instrument.class, 
      Startup.class, 
      Relationship.class,
      Nudge.class,
      AbTest.class
    ]
    t = Time.now
    uas = Cache.arr_get('user_actions')
    Cache.delete('user_actions')
    saved = 0
    UserAction.transaction do
      uas.each do |marshaled_ua|
        begin
          ua = Marshal.load(marshaled_ua)
          if ua.save # count successes
            saved += 1
          else # push failures back onto cache
            Cache.arr_push('user_actions', marshaled_ua)
          end
        rescue
          Cache.arr_push('user_actions', marshaled_ua)
        end
      end
    end
    msg = "User Actions: wrote #{saved} of #{uas.size} user actions in #{Time.now - t} seconds"
    logger.info msg
    msg
  end

  def self.queue_actions?
    @@queue_actions
  end

  def self.queue_actions=(queue_actions)
    @@queue_actions = queue_actions
  end
end
