class Ability
  include CanCan::Ability

  def initialize(user)
    user ||= User.new
    if user.admin?
      can :manage, :all
    elsif !user.new_record?
      can :manage, User, :id => user.id
      can :read, Startup, :onboarding_complete? => true

      if user.startup_id.blank?
        can :manage, Startup, :id => user.startup_id
        can :manage, Checkin do |checkin|
          (Checkin.in_after_time_window? or Checkin.in_before_time_window?) and (checkin.startup_id == user.startup_id)
        end
        can :manage, Relationship do |relationship|
          return true if relationship.entity_type == 'Startup' and relationship.entity_id == user.startup_id
          return true if relationship.connected_with_type == 'Startup' and relationship.connected_with_id == user.startup_id
        end
      end

      can :manage, Relationship do |relationship|
        return true if relationship.entity_type == 'User' and relationship.entity_id == user.id
        return true if relationship.connected_with_type == 'User' and relationship.connected_with_id == user.id
      end

      can :read, Checkin do |checkin|
        return true if checkin.startup_id == user.startup_id
        return true if checkin.startup.checkins_public?
        return true if user.mentor? and user.connected_to?(checkin.startup)
        return true if !user.startup.blank? and user.startup.connected_to?(checkin.startup)
      end

      # Anyone can read meetings
      can :read, Meeting
      can :manage, Meeting, :organizer_id => user.id

      #can :manage, MeetingMessage

      can :read, Comment
      can :manage, Comment, :user_id => user.id

      can :read, Awesome
      can :manage, Awesome, :user_id => user.id
    end

    # Define abilities for the passed in user here. For example:
    #
    #   user ||= User.new # guest user (not logged in)
    #   if user.admin?
    #     can :manage, :all
    #   else
    #     can :read, :all
    #   end
    #
    # The first argument to `can` is the action you are giving the user permission to do.
    # If you pass :manage it will apply to every action. Other common actions here are
    # :read, :create, :update and :destroy.
    #
    # The second argument is the resource the user can perform the action on. If you pass
    # :all it will apply to every resource. Otherwise pass a Ruby class of the resource.
    #
    # The third argument is an optional hash of conditions to further filter the objects.
    # For example, here the user can only update published articles.
    #
    #   can :update, Article, :published => true
    #
    # See the wiki for details: https://github.com/ryanb/cancan/wiki/Defining-Abilities
  end
end