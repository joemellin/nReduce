class CheckinsController < ApplicationController
  around_filter :record_user_action
  before_filter :login_required
  before_filter :current_startup_required

  def index
    # For now only allow access to your own checkin list (future will be to allow investors)
    @startup = @current_startup
    @checkins = @startup.checkins.ordered
  end

  def show
    @startup = Startup.find(params[:startup_id]) unless params[:startup_id].blank?
    params[:id] ||= params[:checkin_id]
    if params[:id] == 'latest'
      @checkin = @startup.checkins.completed.ordered.first
      if @checkin.blank?
        flash[:alert] = "#{@startup.name} hasn't completed any check-ins yet."
        redirect_to @startup
        return
      end
    else
      @checkin = Checkin.find(params[:id])
    end
    if !authorize_view_checkin_or_redirect(@checkin) # only allow owner to edit
      return
    else
      @new_comment = Comment.new(:checkin_id => @checkin.id)
      @comments = @checkin.comments.arrange(:order => :created_at) # arrange in nested order
    end
  end

  def edit
    @startup = @current_startup
    @checkin = Checkin.find(params[:id])
    unless authorize_edit_checkin(@checkin) # only allow owner to edit
      redirect_to(checkins_path)
      return
    end
    set_disabled_states(@checkin)
  end

  def new
    @startup = @current_startup
    @checkin = @current_startup.current_checkin
    if Checkin.in_before_time_window? or Checkin.in_after_time_window?
      # if no checkin, give them a new one
      if @checkin.blank?
        @checkin = Checkin.new
      elsif @checkin.completed? and Checkin.in_before_time_window?
        @checkin = Checkin.new
      elsif !@checkin.new_record? and (Checkin.prev_after_checkin > @checkin.created_at) and Checkin.in_before_time_window?
        @checkin = Checkin.new
      end
    end
    if @checkin.blank?
      flash[:alert] = "Sorry you've missed the check-in times."
      redirect_to checkins_path
    else
      set_disabled_states(@checkin)
      render :action => :edit
    end
  end

  def create
    @startup = @current_startup
    @checkin = Checkin.new(params[:checkin])
    @checkin.startup = @startup
    if @checkin.save
      flash[:notice] = "Your checkin has been saved!"
      redirect_to checkins_path
    else
      set_disabled_states(@checkin)
      render :action => :edit
    end
  end

  def update
    @checkin = Checkin.find(params[:id])
    if !authorize_edit_checkin(@checkin)
      redirect_to @checkin
      return
    else
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
    end
  end

  protected

  def set_disabled_states(checkin)
    @before_disabled = Checkin.in_before_time_window? ? false : true
    @after_disabled = Checkin.in_after_time_window? ? false : true
    if !checkin.new_record?
      @before_disabled = true if checkin.created_at < Checkin.prev_before_checkin
      @after_disabled = true if checkin.created_at < Checkin.prev_after_checkin
    end
  end

    # Loads startup from params, and verifies the logged-in user is connected to them
  def authorize_view_checkin_or_redirect(checkin)
    if @current_startup.id == checkin.startup_id
      @startup == @current_startup
      @owner = true
    else
      # Someone else looking at checkins for a startup
      @startup ||= checkin.startup
      unless @current_startup.connected_to?(@startup)
        flash[:alert] = "Sorry you don't have access to view that checkin because you aren't connected to the startup."
        redirect_to @startup
        return
      end
    end
    true
  end

  def authorize_edit_checkin(checkin)
    if current_user.admin? or (checkin.startup_id == @current_startup.id)
      if Checkin.in_after_time_window? or Checkin.in_before_time_window?
        return true
      else
        flash[:alert] = "You aren't within the 'after' check-in time window."
      end
    else
      flash[:alert] = "You aren't allowed to edit that check-in."
    end
    false
  end
end
