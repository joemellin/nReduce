class CheckinsController < ApplicationController
  around_filter :record_user_action, :only => [:show, :create, :first]
  before_filter :login_required
  before_filter :load_requested_or_users_startup
  load_and_authorize_resource :startup, :except => [:first]
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
    (redirect_to('/') && return) if @force_checkin == true
    @new_comment = Comment.new(:checkin_id => @checkin.id)
    @comments = @checkin.comments.includes(:user).arrange(:order => 'created_at DESC') # arrange in nested order
    @next_checkin = @checkin.next_checkin
    @previous_checkin = @checkin.previous_checkin
  end

  def new
    (redirect_to('/') && return) if @force_checkin == true
    if @checkin.completed?
      flash[:notice] = "Your checkin has already been completed."
      redirect_to @checkin
      return
    end
    @checkin.startup = current_user.startup
    initialize_and_add_instruments(@checkin)
    @current_step = @checkin.current_step == 0 ? 1 : @checkin.current_step
    render :action => :edit
  end

  def create
    @checkin.attributes = params[:checkin]
    @checkin.startup = @startup
    if params[:force_checkin].present?
      @ua = false
      @checkin.save
      redirect_to '/'
    else
      was_completed = @checkin.completed?
      if @checkin.save
        save_completed_state_and_redirect_checkin(@checkin, was_completed)
      else
        @ua = false # don't record user action until they are successful
        initialize_and_add_instruments(@checkin)
        render :action => :edit
      end
    end
    @startup.launched! if params[:startup] && params[:startup][:launched].to_i == 1
  end

  def edit
    (redirect_to('/') && return) if @force_checkin == true
    if @checkin.completed? && params[:current_step].blank?
      flash[:notice] = "Your checkin has already been completed."
      redirect_to @checkin
      return
    end
    @startup ||= @checkin.startup
    initialize_and_add_instruments(@checkin)
    @current_step = params[:current_step].to_i if params[:current_step].present?
    # force above 0
    @current_step = @checkin.current_step == 0 ? 1 : @checkin.current_step
  end

  def update
    @startup ||= @checkin.startup
    was_completed = @checkin.completed?
    if @checkin.update_attributes(params[:checkin])
      save_completed_state_and_redirect_checkin(@checkin, was_completed)
    else
      initialize_and_add_instruments(@checkin)
      render :action => :edit
    end
    @startup.launched! if params[:startup] && params[:startup][:launched].to_i == 1
  end

  # For creating a first checkin
  def first
    @onboard = @hide_background_image = @hide_footer = true
    @force_checkin = false
    @checkin ||= Checkin.new
    @weekly_class = true
    if params[:checkin].present? && params[:checkin][:goal].present? && params[:message].present?
      @checkin.attributes = params[:checkin]
      @checkin.user = current_user
      if @checkin.save(:validate => false)
        current_user.startup.completed_goal!(params[:message], current_user)
        session[:checkin_completed] = true
        redirect_to '/'
      else
        flash[:alert] = "Sorry we couldn't save your goal"
      end
    else
      @checkin.startup = current_user.startup
    end
  end

  protected

  def save_completed_state_and_redirect_checkin(checkin, was_completed)
    session[:checkin_completed] = false
    if checkin.completed?
      unless was_completed
        session[:checkin_completed] = true
      end
      redirect_to relationships_path
    else
      redirect_to edit_checkin_path(checkin)
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
    in_time_window = Checkin.in_time_window?(@startup.checkin_offset)
    if in_time_window
      # if no checkin, give them a new one
      if @checkin.blank?
        @checkin = Checkin.new(:startup => @startup)
      # last week's checkin
      elsif !@checkin.new_record? and (Checkin.prev_checkin_due_at(@startup.checkin_offset) > @checkin.created_at) and in_time_window
        @checkin = Checkin.new(:startup => @startup)
      end
    end
  end

  def initialize_and_add_instruments(checkin)
    @instrument = @startup.instruments.first || Instrument.new(:startup => @startup)
    @checkin.measurement = Measurement.new(:instrument => @instrument) if @checkin.measurement.blank?
    # Set startup as launched if they have established an instrument
    @checkin.startup.launched_at = Time.now unless @instrument.new_record?
    @checkin.video = Video.new if @checkin.video.blank?
    # disable olark
    @recording_video = true
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
