class WeeklyClassesController < ApplicationController
  around_filter :record_user_action, :only => [:show]
  before_filter :login_required
  load_and_authorize_resource

  def show
    # update weekly class stats if this user is new
    @weekly_class.save if current_user.created_at > @weekly_class.updated_at
    # load all stats to compare against previous classes
    @stats = WeeklyClass.top_stats(@weekly_class)
    # load invites by user
    @invite = Invite.new(:weekly_class => @weekly_class, :from_id => current_user.id, :invite_type => Invite::STARTUP)
    @sent_invites = current_user.sent_invites.to_startups.ordered
    @user = current_user
    if (Rails.env.development? || current_user.admin) && params[:join].present?
      @in_time_window = true
    else
      @in_time_window = @weekly_class.in_join_window?
    end
    if @in_time_window
      # Generates session key for startup and initializes user as moderator if they are a part of the startup
      @nreduce = Startup.find(Startup.nreduce_id)
      initialize_tokbox_session(@nreduce)
    end
    load_data(@in_time_window)
  end

  def update_state
    @nreduce = Startup.find(Startup.nreduce_id)
    @user = current_user
    @in_time_window = @weekly_class.in_join_window?
    load_data(@in_time_window)
  end

  # Graduate from the weekly class to enter nReduce
  def graduate
    @startup = current_user.startup
    if @startup.can_enter_nreduce?
      @startup.force_setup_complete!
      flash[:notice] = "Welcome to your new community of founders!"
      redirect_to '/'
    else
      redirect_to current_user.weekly_class
    end
  end

  def join
    redirect_to '/' unless current_user.startup.present?
    # also assign other members of this person's startup
    current_user.startup.team_members.each{|tm| tm.weekly_class = @weekly_class; tm.save(:validate => false) }
    flash[:notice] = "You're now a part of this weekly class!"
    redirect_to @weekly_class
  end

  protected

  def load_data(live_join = false)
    if current_user.startup.blank?
      create_startup
    else
      @startup = current_user.startup
    end
    if live_join
      if params[:last].present?
        begin
          last_polled_at = Time.parse(params[:last])
        rescue
          last_polled_at = nil
        end
      else
        last_polled_at = nil
      end
      load_questions_for_startup(@nreduce, last_polled_at)
    end

    @setup = true
    
    @startups = @weekly_class.startups.uniq.sort{|a,b| a.profile_completeness_percent <=> b.profile_completeness_percent }.reverse
    team_member_ids = @startups.map{|s| s.cached_team_member_ids }.flatten
    @team_members = Hash.by_key(User.find(team_member_ids), :startup_id, nil, true) if team_member_ids.present?

    @can_enter_nreduce = @startup.can_enter_nreduce?
    @profile_elements = @startup.profile_elements(true)
    @profile_completeness_percent = (@startup.profile_completeness_percent * 100).round
    @relationships_by_startup = Hash.by_key(Relationship.where(:connected_with_id => @startup.id, :connected_with_type => @startup.class).all, :entity_id) 
    @pending_relationships_by_startup = Hash.by_key(Relationship.where(:entity_id => @startup.id, :entity_type => @startup.class).pending.all, :connected_with_id) 
  end

  def create_startup
    s = Startup.new
    s.name = "#{current_user.name.possessive} Startup"
    s.save
    current_user.startup = s
    current_user.save(:validate => false)
    @startup = s
  end
end
