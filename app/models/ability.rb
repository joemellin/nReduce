class Ability
  include CanCan::Ability

  # See the wiki for details: https://github.com/ryanb/cancan/wiki/Defining-Abilities

  def initialize(user, params)
    user ||= User.new

    cannot :manage, Video
    cannot [:see_ratings_page, :read_posts], User
    cannot [:read_post, :repost], Comment
    can :add_teams, Relationship

    # Admins can do anything
    if user.admin?
      can :manage, :all
      can :stats, Startup

    # Users who have a startup or are a mentor
    elsif !user.new_record? and user.has_startup_or_is_mentor_or_investor?
    
      # Abilities if user has a startup
      if user.startup_id.present?
        can [:manage, :onboard, :onboard_next, :remove_team_member], Startup, :id => user.startup_id

        cannot :invite_mentor, Startup # have to remove this ability since we just assigned manage

        can :invite_mentor, Startup do |startup|
          startup.can_access_mentors_and_investors?
        end
        
        # Can start a checkin if in before or after time window and their startup owns checkin
        can [:new, :create], Checkin if Checkin.in_time_window?(user.startup.checkin_offset)

        # Can edit a checkin if in the before/after time window and they own it
        can [:edit, :update], Checkin do |checkin|
          Checkin.in_time_window?(user.startup.checkin_offset) && (checkin.startup_id == user.startup_id)
        end

        can :first, Checkin if !user.account_setup?

        can :create, Checkin if user.startup.current_checkin.blank?

        can :destroy, Checkin, :startup_id => user.startup_id

        # Can manage if they created it
        can :manage, Invite, :startup_id => user.startup_id

        can :manage, Nudge, :startup_id => user.startup_id

        can :manage, Instrument do |m|
          m.startup_id == user.startup_id
        end

        can [:new, :create], Instrument

        can :manage, Video, :startup_id => user.startup_id

        # Allow them to see ratings page because they need to turn on/off investable and mentorable
        can :read, Rating, :startup_id => user.startup_id

        # This is only if they have selected as investable or mentorable and pass all req's
        can :see_ratings_page, User if user.startup.can_access_mentors_and_investors?

        can :read_post, Comment do |c|
          c.original_post? # Josh: just return true for now && c.can_be_viewed_by?(user)
        end
        can :repost, Comment do |c|
          true # Josh: just erturn true for now so anyone can see anything c.can_be_viewed_by?(user)
        end

        can [:read], Request

        # Can create a new request only if they have a balance that permits it in their account
        can [:new, :create], Request do |r|
          u.startup.helpful_balance >= r.price
        end

        can :manage, Request, :startup_id => user.startup_id
        
        # Anyone on a startup can help another startup, as long as they didn't post it
        can [:new, :create], Response do |r|
          r.request.startup_id != user.startup_id
        end

        # Can manage response if it was created by that user
        can :manage, Response, :user_id => user.id

        # Can read, accept a response if on the startup team - and request still isn't in progress
        can [:read, :accept], Response do |r|
          r.request_id.present? && !r.started? && r.request.startup_id == user.startup_id 
        end

        # Can reject a response if on startup team and response hasn't already been accepted
        can :reject, Response do |r|
          r.startup_id == user.startup_id && !r.accepted?
        end

        can :thank_you, Response do |r|
          r.request.startup_id == user.startup_id
        end
      end

      # Can destroy if they were assigned as receiver or created it
      can :destroy, Invite do |invite|
        invite.to == user || invite.from == user
      end

      # They can accept the invite if it's still active and their email matches invite email  or they are assigned as "to"
      can :accept, Invite do |invite|
        invite.active? && (invite.to == user) || (invite.email == user.email)
      end

      can :read, Checkin do |checkin|
        # From user's startup
        if checkin.startup_id == user.startup_id
          true
        # The checkin's startup has listed all as public
        elsif checkin.startup.checkins_public?
          true
        # This user is a startup's mentor
        elsif (user.mentor? || user.investor?) && user.connected_to?(checkin.startup)
          true
        # This user's startup is connected
        elsif !user.startup.blank? && user.startup.connected_to?(checkin.startup)
          true
        else
          false
        end
      end

      can :read, Video do |video|
        # From user's startup
        if video.startup_id == user.startup_id
          true
        # The checkin's startup has listed all as public
        elsif video.startup.checkins_public?
          true
        # This user is a startup's mentor
        elsif (user.mentor? || user.investor?) && user.connected_to?(video.startup)
          true
        # This user's startup is connected
        elsif !user.startup.blank? && user.startup.connected_to?(video.startup)
          true
        else
          false
        end
      end

      # User with startup or mentor can create a relationship
      can :create, Relationship do |relationship|
        if user.has_startup_or_is_mentor_or_investor?
          if (user.mentor? || user.investor?) && relationship.is_involved?(user)
            true
          elsif !user.startup.blank? and relationship.is_involved?(user.startup)
            true
          else
            true
          end
        else
          false
        end
      end

      # Only connected_with party can approve relationship
      can :approve, Relationship do |relationship|
        if relationship.connected_with_type == 'User' && relationship.connected_with_id == user.id
          true
        elsif relationship.connected_with_type == 'Startup' && relationship.connected_with_id == user.startup_id
          true
        # if suggested relatinship, this will allow the user who it was suggested to, to change relationship to pending
        elsif relationship.suggested? && relationship.entity_type == 'Startup' and relationship.entity_id == user.startup_id
          true
        elsif relationship.suggested? && relationship.entity_type == 'User' and relationship.entity_id == user.id
          true
        else
          false
        end
      end

      # Either party can reject a relationship
      can :reject, Relationship do |relationship|
        if (user.mentor? || user.investor?) && relationship.is_involved?(user)
          true
        elsif !user.startup.blank? and relationship.is_involved?(user.startup)
          true
        else
          false
        end
      end 

      # Keep more specific rules at the top, as they are overwritten by broader abilities further down
      
      can [:manage, :cancel_edit], Comment, :user_id => user.id

      # Can comment on any checkin they are allowed to read
      # TODO: anyone with startup or mentor can comment on anything (if they can somehow construct the form)
      can [:read, :create, :reply_to], Comment

      can :manage, Awesome, :user_id => user.id

      # TODO: anyone with startup or mentor can awesome anything (if they can somehow construct the form)
      can [:read, :create], Awesome

      can :manage, Notification, :user_id => user.id
      can :manage, Nudge, :from_id => user.id

      # Only organizer can manage meetings
      can :manage, Meeting, :organizer_id => user.id

      # Anyone can see all meetings
      can :read, Meeting

      # Only organizer can view/send meeting messages
      can :manage, MeetingMessage, :meeting => { :organizer_id => user.id }

      # User can only manage their own authentications
      can [:read, :destroy], Authentication, :user_id => user.id

      cannot :intro_video, Startup

      # Startup can view relationships they are involved in
      if !user.startup_id.blank?
        can :read, Relationship do |relationship|
          relationship.is_involved?(user.startup)
        end
        can :intro_video, Startup do |s|
          s.checkins.count == 0
        end
      end

      # Mentor/Investor can view relationships they are involved in (index)
      if user.mentor? || user.investor?
        can :read, Relationship do |relationship|
          relationship.is_involved?(user)
        end
      end

      # All users with startup/mentor can view a startup if onboarding is complete
      can :read, Startup do |s|
        s.account_setup?
      end

      # Anyone with a startup can upload a screenshot
      can [:new, :create], Screenshot unless user.startup_id.blank?

      # Anyone can manage a screenshot that is on that startup
      can :manage, Screenshot do |s|
        s.startup_id == user.startup_id
      end
    end

    #
    # All Users
    #

    # Only conversation participants can modify
    can :manage, Conversation do |c|
      c.participant_ids.include?(user.id)
    end

    # Anyone can start a new conversation
    can [:new, :create], Conversation

    can [:new, :create], Invite

    cannot :all, WeeklyClass
    can [:read, :update_state, :graduate], WeeklyClass, :id => user.weekly_class_id
    
    if user.startup_id.present?
      can :graduate, WeeklyClass do |w|
        user.weekly_class_id == w.id && user.startup.can_enter_nreduce?
      end
    end

    # Can only create a startup if registration is open and they don't have a current startup
    can [:new, :create, :edit], Startup if user.startup_id.blank?

    # User can only manage their own account
    can [:manage, :onboard, :onboard_next], User, :id => user.id

    # Anyone can see a screenshot
    can :read, Screenshot

    # Have to override manage roles on user for mentors
    unless user.admin?
      cannot :change_mentor_status, User
      cannot :see_mentor_page, User
      cannot :search_mentors, User

      cannot :see_investor_page, User
      cannot :investor_connect_with_startups, User
    end
    
    if user.mentor?
      can :change_mentor_status, User
      # If they are a mentor of any kind they can see the mentors page
      can :see_mentor_page, User if user.roles?(:mentor) or user.roles?(:nreduce_mentor)
      # If they are an nreduce mentor they can see other mentors
      can :search_mentors, User if user.roles?(:nreduce_mentor)
    elsif !user.startup_id.blank?

      # Any user with a startup can see the basic req's for a mentor
      can :see_mentor_page, User

      # A user with a startup can search mentors if they are able to invite them
      can :search_mentors, User do |u|
        u.startup.can_access_mentors_and_investors?
      end
    end

    if user.investor? || user.nreduce_mentor?
      can [:new, :create], Rating
      can :manage, Rating, :user_id => user.id 
    end
    
    # For now just show investor page to other investors or users with a startup
    can :see_investor_page, User do |u|
      u.investor? || (u.entrepreneur? and !u.startup_id.blank?)
    end

    can :see_ratings_page, User if user.mentor? || user.investor?

    # Investor can see startups if they have contacted less than one startup this week.
    can :investor_mentor_connect_with_startups, User do |u|
      (u.investor? || u.nreduce_mentor?) && u.can_connect_with_startups?
    end

    # Investors can't review startups to add teams
    cannot :add_teams, Relationship if user.investor?

    # Everyone can see users
    can :read, User

    cannot [:chat, :reset_hipchat_account], User
    can [:chat, :reset_hipchat_account], User do |u|
      u.can_access_chat?
    end

    # Can manage video if they own it
    can :manage, Video, :user_id => user.id

    # Anyone can create a new video
    can [:new, :record, :create], Video

    cannot :read, Startup

    # Everyone can see a startup's profile unless they are private
    can [:mini_profile, :read], Startup do |s|
      if s.public?
        true
      elsif !user.startup_id.blank? and s.id == user.startup_id
        true
      else
        false
      end
    end

    can [:new, :create, :support], Question
    can :manage, Question, :user_id => user.id
    can :answer, Question do |q|
      user.startup_id == q.startup_id
    end

    can [:new, :create], Rsvp
    can :manage, Rsvp do |r|
      r.user_id == user.id
    end
  
    # Anyone can see demo day
    can [:read, :show, :show_startup], DemoDay

    cannot :read_posts, User unless user.startup_id.present?
  end
end