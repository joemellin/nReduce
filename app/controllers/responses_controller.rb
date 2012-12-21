class ResponsesController < ApplicationController
  before_filter :login_required
  before_filter :load_requested_or_users_startup
  load_and_authorize_resource :request, :except => [:thank_you]
  load_and_authorize_resource :response, :through => :request, :except => [:thank_you]
  load_and_authorize_resource :only => [:thank_you]

  def show
    if @response.started?
      if @response.should_be_expired?
        @response.expire!
        flash.now[:notice] = "Sorry but you took too long to respond, this request has expired."
      elsif @response.video.blank?
        @response.video = Screenr.new 
        @recording_video = true
      end
    end
  end

  def new
    # if they auth'd and then came to complete task that can be completed, just do it
    if @response.can_be_completed?
      if @response.complete!
        redirect_to '/'
      else
        flash.now[:alert] = @response.errors.full_messages.join('. ')
        render :action => :edit
      end
      return
    end
  end

  def create
    @response.user = current_user
    @response.request = @request
    if @response.can_be_completed? && @response.complete!
      # store response id to show success message
      session[:response_success_id] = @response.id
      redirect_to '/'
    elsif @response.save
      redirect_to [@request, @response]
    else
      flash.now[:alert] = @response.errors.full_messages.join('. ')
      render :action => :edit
    end
  end

  def edit

  end

  def update
    @response.attributes = params[:response]
    if @response.can_be_completed? ? @response.complete! : @response.save
      redirect_to [@request, @response]
    else
      flash[:alert] = @response.errors.full_messages.join('. ')
      render :action => :edit
    end
  end

  def complete
    @response.complete!
    redirect_to [@request, @response]
  end

  def accept
    @response.accept!
    redirect_to [@request, @response]
  end

  def cancel
    @response.cancel!
    redirect_to [@request, @response]
  end

  def reject
    @response.reject!(params[:reject_because])
    redirect_to [@request, @response]
  end

  def thank_you
    # redirect to message
    @response.thanked!
    redirect_to new_conversation_path(:startup_id => @response.user.startup.to_param)
  end
end