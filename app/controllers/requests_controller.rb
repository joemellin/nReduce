class RequestsController < ApplicationController
  before_filter :login_required
  before_filter :load_requested_or_users_startup
  load_and_authorize_resource 

  def new
    # hardcode only request type available for now - and have to initialize or else price isn't set
    num = params[:num].present? ? params[:num].to_i : 1
    num = 10 if num > 10
    @request = UsabilityTestRequest.new(:startup => current_user.startup, :num => num)
    #@request = RetweetRequest.new(:startup => current_user.startup, :num => num)
    @request.data[0] = params[:tweet_url] if params[:tweet_url].present?
  end

  def create
    @request = params[:request][:type].constantize.new(params[:request]) unless params[:request][:type].blank?
    logger.info @request.inspect
    @request.user = current_user
    @request.startup = current_user.startup
    if @request.save
      flash[:notice] = "Your help request has been posted! We'll let you know as soon as someone responds."
      redirect_to '/'
    else
      render :action => :edit
    end
  end

  def edit

  end

  def update
    if @request.save
      redirect_to @request
    else
      render :action => :edit
    end
  end

  def cancel
    if @request.cancel!
      redirect_to '/'
    else
      render :action => :edit
    end
  end
end
