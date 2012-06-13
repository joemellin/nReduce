class CheckinsController < ApplicationController
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
      @checkin = @startup.checkins.ordered.first
      if @checkin.blank?
        flash[:alert] = "#{@startup.name} hasn't made any check-ins yet."
        redirect_to @startup
        return
      end
    else
      @checkin = Checkin.find(params[:id])
    end
    return unless authorize_view_checkin(@checkin) # only allow owner to edit
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
    @checkin = @current_startup.current_checkin
    if @checkin.blank? or Checkin.in_before_time_window?
      @checkin = Checkin.new
    end
    if @checkin.blank?
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
      redirect_to '/'
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
        redirect_to '/'
      else
        redirect_to edit_checkin_path(@checkin)
      end
    else
      render :action => :edit
    end
  end

  protected

    # Loads startup from params, and verifies the logged-in user is connected to them
  def authorize_view_checkin(checkin)
    if @current_startup.id == checkin.startup_id
      @startup == @current_startup
      @owner = true
    else
      # Someone else looking at checkins for a startup
      @startup ||= checkin.startup
      unless @current_startup.connected_to?(@startup)
        flash[:alert] = "Sorry you don't have access to view that startup because you aren't connected to them."
        redirect_to relationships_path
        return
      end
    end
    true
  end

  def authorize_edit_checkin(checkin)
    return true if current_user.admin? or (checkin.startup_id == @current_startup.id)
    false
  end
end
