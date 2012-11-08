class DemoDayController < ApplicationController
  #before_filter :only_allow_in_staging
  before_filter :login_required, :only => [:attend]
  #before_filter :load_and_validate_demo_day
  load_and_authorize_resource :only => [:show, :show_startup]

  def index
    @demo_days = DemoDay.where(['day <= ?', Date.today]).ordered
    @demo_day = @demo_days.shift
    @next_demo_day = @demo_day.next_demo_day if @demo_day.in_the_past?
    @question_count = Question.group('startup_id').unanswered.count if @demo_day.present? && @demo_day.in_time_window?
  end

  def show
    @question_count = Question.group('startup_id').unanswered.count if @demo_day.in_time_window?
    @next_demo_day = DemoDay.ordered.first if @demo_day.in_the_past?
  end

    # Show a specific company
  def show_startup
    # support legacy urls
    if params[:old_id].present?
     @demo_day = DemoDay.where(:day => '2012-10-03').first
     @startup = Startup.find(@demo_day.startup_ids[params[:startup_index].to_i])
    else
      #id = params[:startup_id].split('-').first
      @startup = Startup.find_by_obfuscated_id(params[:startup_id]) if params[:startup_id].present?
    end
    @next_demo_day = DemoDay.ordered.first if @demo_day.in_the_past?
    @in_time_window = @demo_day.in_time_window?
    @after = true
    if @demo_day.includes_startup?(@startup)
      # Load all checkins made before demo day
      #@checkins = @startup.checkins.where(['created_at < ?', "#{@demo_day.day} 00:00:00"]).ordered.includes(:before_video, :after_video)
    else
      redirect_to :action => :index
      return
    end
    
    # initialize tokbox and force new session key
    if @in_time_window
      initialize_tokbox_session(@startup, user_signed_in? && current_user.startup_id == @startup.id)

      load_questions_for_startup(@startup)
    end
    
    @num_checkins = @startup.checkins.count
    @num_awesomes = @startup.awesomes.count
    @screenshots = @startup.screenshots.ordered

    @video = @demo_day.video_for_startup(@startup)
  end

  # Register that you've attended demo day
  def attend
    @demo_day.add_attendee!(current_user)
    redirect_to :action => :index
  end
end
