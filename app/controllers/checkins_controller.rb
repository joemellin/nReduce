class CheckinsController < ApplicationController
  before_filter :startup_required

  def index
    @checkins = @startup.checkins.order('created_at DESC')
  end

  def edit
    @checkin = Checkin.find(params[:id])
    redirect_to(checkins_path) && return unless authorize_checkin(@checkin)
  end

  def show
    @checkin = Checkin.find(params[:id])
    redirect_to(checkins_path) && return unless authorize_checkin(@checkin)
  end

  def new
    week_id = Week.id_for_time(Time.now)
    if !week_id
      flash[:alert] = "Sorry you can't check in this week"
      redirect_to startup_dashboard_path
    else
      @checkin = @startup.checkins.where(:week_id => week_id).first || Checkin.new(:week_id => week_id)
      render :action => :edit
    end
  end

  def create
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

  def authorize_checkin(checkin)
    current_user.admin? or checkin.startup_id == @startup.id
  end
end
