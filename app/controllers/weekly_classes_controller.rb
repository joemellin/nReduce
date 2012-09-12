class WeeklyClassesController < ApplicationController
  before_filter :login_required
  load_and_authorize_resource

  def show
    @stats = WeeklyClass.top_stats
    @invite = Invite.new(:weekly_class => @weekly_class, :from_id => current_user.id, :invite_type => Invite::STARTUP)
    @sent_invites = current_user.sent_invites.to_startups.ordered
    @startup = current_user.startup
    @user = current_user
    @in_time_window = true # @weekly_class.in_join_window?
    if @in_time_window
      @nreduce = Startup.find_by_obfuscated_id(Startup.nreduce_id)
      # Generates session key for startup and initializes user as moderator if they are a part of the startup
      initialize_tokbox_session(@nreduce)
      load_questions_for_startup(@nreduce)
      @startups = @weekly_class.startups.sort{|a,b| a.profile_completeness_percent <=> b.profile_completeness_percent }.reverse
      @profile_elements = @startup.profile_elements
      @profile_completeness_percent = (@startup.profile_completeness_percent * 100).round
    else
      @weekly_class.save #recalc stats
    end
    render :action => @in_time_window ? 'show' : 'wait'
  end
end
