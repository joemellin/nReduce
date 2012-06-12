class CheckinsController < ApplicationController
  before_filter :current_startup_required
  before_filter :load_startup_and_verify_access, :only => [:show]

  def index
    # For now only allow access to your own checkin list (future will be to allow investors)
    @startup = @current_startup
    @checkins = @startup.checkins.ordered
  end

  def show
    params[:id] ||= params[:checkin_id]
    if params[:id] == 'latest'
      @checkin = @startup.checkins.ordered.first
      if @checkin.blank?
        flash[:alert] = "#{@startup.name} hasn't made any check-ins yet."
        redirect_to @startup
        return
      end
    else
      @checkin = Checkin.find(params[:id])
    end
    @new_comment = Comment.new(:checkin_id => @checkin.id)
    @comments = @checkin.comments.ordered
  end

  def edit
    @startup = @current_startup
    @checkin = Checkin.find(params[:id])
    redirect_to(checkins_path) && return unless authorize_edit_checkin(@checkin) # only allow owner to edit
  end

  def new
    @startup = @current_startup
    if @startup.current_checkin and Checkin.in_after_time_window?
      @checkin = @startup.current_checkin
    elsif Checkin.in_before_time_window?
      @checkin = Checkin.new
    else
      flash[:alert] = "Sorry you've missed the check-in times."
      redirect_to root_path
      return
    end
    render :action => :edit
  end

  def create
    @startup = @current_startup
    @checkin = Checkin.new(params[:checkin])
    @checkin.startup = @startup
    if @checkin.save
      flash[:notice] = "Your checkin has been saved!"
      redirect_to startup_onboard_path
    else
      render :action => :edit
    end
  end

  def update
    @checkin = Checkin.find(params[:id])
    return unless authorize_edit_checkin(@checkin)
    if @checkin.update_attributes(params[:checkin])
      if @checkin.completed?
        flash[:notice] = "Your check-in has been completed!"
        redirect_to checkins_path
      else
        redirect_to edit_checkin_path(@checkin)
      end
    else
      render :action => :edit
    end
  end

  protected

    # Loads startup from params, and verifies the logged-in user is connected to them
  def load_startup_and_verify_access
    if params[:startup_id].blank?
      # User viewing own checkins
      @startup = @current_startup
      @owner = true
    else
      # Someone else looking at checkins for a startup
      @startup = Startup.find(params[:startup_id])
      unless @current_startup.connected_to?(@startup)
        flash[:alert] = "Sorry you don't have access to view that startup because you aren't connected to them."
        redirect_to relationships_path
        return
      end
    end
    true
  end

  def authorize_edit_checkin(checkin)
    current_user.admin? or checkin.startup_id == @current_startup.id
  end
end
