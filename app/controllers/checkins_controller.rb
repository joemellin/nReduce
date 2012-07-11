class CheckinsController < ApplicationController
  around_filter :record_user_action
  before_filter :login_required
  before_filter :load_requested_or_users_startup
  load_and_authorize_resource :startup
  before_filter :load_latest_checkin, :only => :show
  before_filter :load_current_checkin, :only => :new
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

  def edit
    set_disabled_states(@checkin)
    @ua = {:attachable => @checkin}
  end

  def new
    set_disabled_states(@checkin)
    render :action => :edit
  end

  def create
    @checkin.startup = @startup
    if @checkin.save
      flash[:notice] = "Your checkin has been saved!"
      redirect_to checkins_path
    else
      set_disabled_states(@checkin)
      render :action => :edit
    end
    @ua = {:attachable => @checkin}
  end

  def update
    if @checkin.update_attributes(params[:checkin])
      if @checkin.completed?
        flash[:notice] = "Your check-in has been completed!"
        redirect_to '/'
      else
        redirect_to edit_checkin_path(@checkin)
      end
    else
      set_disabled_states(@checkin)
      render :action => :edit
    end
    @ua = {:attachable => @checkin}
  end

  protected

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

  def set_disabled_states(checkin)
    @before_disabled = Checkin.in_before_time_window? ? false : true
    @after_disabled = Checkin.in_after_time_window? ? false : true
    if !checkin.new_record?
      @before_disabled = true if checkin.created_at < Checkin.prev_before_checkin
      @after_disabled = true if checkin.created_at < Checkin.prev_after_checkin
    end
  end
end
