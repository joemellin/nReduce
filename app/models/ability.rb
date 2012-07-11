class Ability
  include CanCan::Ability

  # See the wiki for details: https://github.com/ryanb/cancan/wiki/Defining-Abilities

  def initialize(user, params)
    user ||= User.new

    cannot :invite_mentor, Startup
    
    if user.admin?
      can :manage, :all
      can :stats, Startup

    elsif !user.new_record? and user.has_startup_or_is_mentor?

      # Abilities if user has a startup
      if !user.startup_id.blank?
        can [:manage, :dashboard, :onboard, :onboard_next, :remove_team_member], Startup, :id => user.startup_id
        
        # Can start a checkin if in before or after time window and their startup owns checkin
        can [:new, :create], Checkin if Checkin.in_after_time_window? or Checkin.in_before_time_window?

        # Can edit a checkin if in the before/after time window and they own it
        can [:edit, :update], Checkin do |checkin|
          (Checkin.in_after_time_window? or Checkin.in_before_time_window?) and (checkin.startup_id == user.startup_id)
        end

        can :destroy, Checkin, :startup_id => user.startup_id

        # Can manage if they created it
        can :manage, Invite, :startup_id => user.startup_id

        can :manage, Nudge, :startup_id => user.startup_id

        can :invite_mentor, Startup do |startup|
          startup.can_invite_mentor?
        end
      end

      # Can destroy if they were assigned as receiver or created it
      can :destroy, Invite do |invite|
        invite.to == user || invite.from == user
      end

      # They can accept the invite if it's still active and their email matches invite email  or they are assigned as "to"
      can :accept, Invite do |invite|
        invite.active? and (invite.to == user) || (invite.email == user.email)
      end

      can :read, Checkin do |checkin|
        # From user's startup
        if checkin.startup_id == user.startup_id
          true
        # The checkin's startup has listed all as public
        elsif checkin.startup.checkins_public?
          true
        # This user is a startup's mentor
        elsif user.mentor? and user.connected_to?(checkin.startup)
          true
        # This user's startup is connected
        elsif !user.startup.blank? and user.startup.connected_to?(checkin.startup)
          true
        else
          false
        end
      end

      # User with startup or mentor can create a relationship
      can :create, Relationship do |relationship|
        if user.has_startup_or_is_mentor?
          if user.mentor? and relationship.is_involved?(user)
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
        if relationship.connected_with_type == 'User' and relationship.connected_with_id == user.id
          true
        elsif relationship.connected_with_type == 'Startup' and relationship.connected_with_id == user.startup_id
          true
        else
          false
        end
      end

      # Either party can reject a relationship
      can :reject, Relationship do |relationship|
        if user.mentor? and relationship.is_involved?(user)
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


      # Startup can view relationships they are involved in
      if !user.startup_id.blank?
        can :read, Relationship do |relationship|
          relationship.is_involved?(user.startup)
        end
      end

      # Mentor can view relationships they are involved in (index)
      if user.mentor?
        can :read, Relationship do |relationship|
          relationship.is_involved?(user)
        end
      end

      # All users with startup/mentor can view a startup if onboarding is complete
      can :read, Startup, :onboarding_complete? => true
    end

    # Can only create a startup if registration is open and they don't have a current startup
    can [:new, :create], Startup do |startup|
      Startup.registration_open? and user.startup_id.blank?
    end

    # User can only manage their own account
    can [:manage, :onboard, :onboard_next], User, :id => user.id

    # Everyone can see users
    can :read, User
  end
end