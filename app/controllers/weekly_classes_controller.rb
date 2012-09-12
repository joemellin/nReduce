class WeeklyClassesController < ApplicationController
  before_filter :login_required
  load_and_authorize_resource

  def show
    @stats = WeeklyClass.top_stats
    @invite = Invite.new(:weekly_class => @weekly_class, :from_id => current_user.id, :invite_type => Invite::STARTUP)
    @sent_invites = current_user.sent_invites.to_startups.ordered
    @startup = current_user.startup
    @user = current_user
    @in_time_window = @weekly_class.in_join_window?
    if @in_time_window
      if @startup.blank?
        s = Startup.new
        s.name = "#{current_user.name.possessive} Startup"
        s.save
        current_user.startup = s
        current_user.save(:validate => false)
        @startup = s
      end
      # Generates session key for startup and initializes user as moderator if they are a part of the startup
      @nreduce = Startup.find_by_obfuscated_id(Startup.nreduce_id)
      initialize_tokbox_session(@nreduce)
      load_data
    else
      @weekly_class.save #recalc stats
    end
    render :action => @in_time_window ? 'show' : 'wait'
  end

  def update_state
    @nreduce = Startup.find_by_obfuscated_id(Startup.nreduce_id)
    @startup = current_user.startup
    @user = current_user
    load_data
  end

  protected

  def load_data
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
    @startups = @weekly_class.startups.sort{|a,b| a.profile_completeness_percent <=> b.profile_completeness_percent }.reverse
    @profile_elements = @startup.profile_elements
    @profile_completeness_percent = (@startup.profile_completeness_percent * 100).round
    @relationships_by_startup = Hash.by_key(Relationship.where(:connected_with_id => @startup.id, :connected_with_type => @startup.class).all, :entity_id) 
    @pending_relationships_by_startup = Hash.by_key(Relationship.where(:entity_id => @startup.id, :entity_type => @startup.class).pending.all, :connected_with_id) 
  end
end
