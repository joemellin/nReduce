class Ability
  include CanCan::Ability

  # See the wiki for details: https://github.com/ryanb/cancan/wiki/Defining-Abilities

  def initialize(user)
    user ||= User.new
    if user.admin?
      can :manage, :all
      can :stats, Startup

    elsif !user.new_record? and user.has_startup_or_is_mentor?
      # Keep more generic rules at top, as they are overwritten by ones further down
      
      can [:manage, :cancel_edit], Comment, :user_id => user.id

      can :manage, Awesome, :user_id => user.id
      can :manage, Notification, :user_id => user.id
      can :manage, Nudge, :from_id => user.id

      # Anyone can see all meetings
      can :read, Meeting

      # Only organizer can manage meetings
      can :manage, Meeting, :organizer_id => user.id

      # Only organizer can view/send meeting messages
      can :manage, MeetingMessage, :meeting => { :organizer_id => user.id }

      # User can only manage their own account
      can :manage, User, :id => user.id

      # User can only manage their own authentications
      can [:read, :destroy], Authentication, :user_id => user.id

      # Can only create a startup if registration is open and they don't have a current startup
      can [:new, :create], Startup do |startup|
        Startup.registration_open? and user.startup_id.blank?
      end

      # Can't view a startup unless onboarding is complete
      can :read, Startup, :onboarding_complete? => true

      # Mentor can view relationships they are involved in (index)
      if user.mentor?
        can :read, Relationship do |relationship|
          relationship.is_involved?(user)
        end
      end

      # User with startup or mentor can create a relationship
      can :create, Relationship do |relationship|
        if user.has_startup_or_is_mentor?
          return true if user.mentor? and relationship.is_involved?(user) 
          return true if !user.startup.blank? and relationship.is_involved?(user.startup)
        end
      end

      # Only connected_with party can approve relationship
      can :approve, Relationship do |relationship|
        return true if relationship.connected_with_type == 'User' and relationship.connected_with_id == user.id
        return true if relationship.connected_with_type == 'Startup' and relationship.connected_with_id == user.startup_id
        false
      end

      # Either party can reject a relationship
      can :reject, Relationship do |relationship|
        return true if user.mentor? and relationship.is_involved?(user)
        return true if user.startup.blank? and relationship.is_involved?(user.startup)
        false
      end 

      # Can destroy if they were assigned as receiver or created it
      can :destroy, Invite, do |invite|
        invite.to == user || invite.from == user
      end

      # They can accept the invite if it's still active and their email matches invite email  or they are assigned as "to"
      can :accept, Invite do |invite|
        invite.active? and (invite.to == user) || (invite.email == user.email)
      end

      can :read, Checkin do |checkin|
        # From user's startup
        return true if checkin.startup_id == user.startup_id
        # The checkin's startup has listed all as public
        return true if checkin.startup.checkins_public?
        # This user is a startup's mentor
        return true if user.mentor? and user.connected_to?(checkin.startup)
        # This user's startup is connected
        return true if !user.startup.blank? and user.startup.connected_to?(checkin.startup)
        false
      end

      # Abilities if user has a startup
      if !user.startup_id.blank?
        can [:manage, :dashboard, :onboard, :onboard_next, :remove_team_member], Startup, :id => user.startup_id
        
        # Can manage checkin if in before or after time window and their startup owns checkin
        can [:new, :edit, :update], Checkin do |checkin|
          (Checkin.in_after_time_window? or Checkin.in_before_time_window?) and (checkin.startup_id == user.startup_id)
        end

        can :destroy, Checkin, :startup_id => user.startup_id

        # Can manage if they created it
        can :manage, Invite, :startup_id => user.startup_id

        can :manage, Nudge, :startup_id => user.startup_id

        can :read, Relationship do |relationship|
          relationship.is_involved?(user.current_startup)
        end
      end
    end
  end
end