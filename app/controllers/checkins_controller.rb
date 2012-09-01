class CheckinsController < ApplicationController
  around_filter :record_user_action
  before_filter :login_required
  before_filter :load_requested_or_users_startup
  load_and_authorize_resource :startup
  before_filter :load_latest_checkin, :only => :show
  before_filter :load_current_checkin, :only => :new
  before_filter :load_obfuscated_checkin, :only => [:show, :edit, :update]
  load_and_authorize_resource :checkin

  def index
    @checkins = @startup.checkins
    authorize! :read, Checkin.new(:startup => @startup)
    @checkins = @checkins.ordered
  end

  def show
    @new_comment = Comment.new(:checkin_id => @checkin.id)
    @comments = @checkin.comments.includes(:user).arrange(:order => 'created_at DESC') # arrange in nested order
    @ua = {:attachable => @checkin}
  end

  def new
    set_disabled_states_and_add_measurement(@checkin)
    @checkin.startup = current_user.startup
    render :action => :edit
  end

  def create
    was_completed = @checkin.completed?
    @checkin.startup = @startup
    @checkin.valid?
    if @checkin.save
      save_completed_state_and_redirect_checkin(@checkin, was_completed)
    else
      set_disabled_states_and_add_measurement(@checkin)
      render :action => :edit
    end
    @startup.launched! if params[:startup] && params[:startup][:launched].to_i == 1
    @ua = {:attachable => @checkin}
  end

  def edit
    @startup ||= @checkin.startup
    set_disabled_states_and_add_measurement(@checkin)
    @ua = {:attachable => @checkin}
  end

  def update
    @startup ||= @checkin.startup
    was_completed = @checkin.completed?
    if @checkin.update_attributes(params[:checkin])
      save_completed_state_and_redirect_checkin(@checkin, was_completed)
    else
      set_disabled_states_and_add_measurement(@checkin)
      render :action => :edit
    end
    @startup.launched! if params[:startup] && params[:startup][:launched].to_i == 1
    @ua = {:attachable => @checkin}
  end

  protected

  def save_completed_state_and_redirect_checkin(checkin, was_completed)
    session[:checkin_completed] = false
    if checkin.completed?
      unless was_completed
        session[:checkin_completed] = true
        # Generate suggested startups if this isn't just an update
        checkin.startup.delete_suggested_startups
        checkin.startup.generate_suggested_connections
      end
      redirect_to add_teams_relationships_path
    else
      redirect_to relationships_path
    end
  end

  def load_latest_checkin
    if params[:checkin_id] == 'latest' and !@startup.blank?
      @checkin = @startup.checkins.completed.ordered.first
      if @checkin.blank?
        flash[:alert] = "#{@startup.name} hasn't completed any check-ins yet."
        redirect_to @startup
        return
      end
    end
  end

  def load_current_checkin
    @checkin = @startup.current_checkin unless @startup.blank?
    if Checkin.in_before_time_window? or Checkin.in_after_time_window?
      # if no checkin, give them a new one
      if @checkin.blank?
        @checkin = Checkin.new
      elsif @checkin.completed? and Checkin.in_before_time_window?
        @checkin = Checkin.new
      # last week's checkin
      elsif !@checkin.new_record? and (Checkin.prev_after_checkin > @checkin.created_at) and (Checkin.in_before_time_window? or Checkin.in_after_time_window?)
        @checkin = Checkin.new
      end
    end
  end

  def set_disabled_states_and_add_measurement(checkin)
    @before_disabled = Checkin.in_before_time_window? ? false : true
    @after_disabled = Checkin.in_after_time_window? ? false : true
    if !checkin.new_record?
      @before_disabled = true if checkin.created_at < Checkin.prev_before_checkin
      @after_disabled = true if checkin.created_at < Checkin.prev_after_checkin
    end
    @instrument = @startup.instruments.first || Instrument.new(:startup => @startup)
    @checkin.measurement = Measurement.new(:instrument => @instrument) if @checkin.measurement.blank?
    @checkin.before_video = ViddlerVideo.new if @checkin.before_video.blank?
    @checkin.after_video = ViddlerVideo.new if @checkin.after_video.blank?
  end

  def load_obfuscated_checkin
    begin
      @checkin ||= Checkin.find_by_obfuscated_id(params[:id])
    rescue ActiveRecord::RecordNotFound
      redirect_to '/'
      return
    end
  end
end
