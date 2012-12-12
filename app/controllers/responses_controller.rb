class ResponsesController < ApplicationController
  before_filter :login_required
  before_filter :load_requested_or_users_startup
  load_and_authorize_resource :request
  load_and_authorize_resource :response, :through => :request

  def show
  end

  def new
  end

  def create
    @response.user = current_user
    @response.request = @request
    if @response.can_be_completed? ? @response.complete! : @response.save
      session[:response_success_id] = @response.id
      # redirect_to [@request, @response]
      redirect_to '/'
    else
      flash.now[:alert] = @response.errors.full_messages.join('. ')
      render :action => :edit
    end
  end

  def edit

  end

  def update
    if @response.can_be_completed? ? @response.complete! : @response.save
      redirect_to [@request, @response]
    else
      flash[:alert] = @response.errors.full_messages.join('. ')
      render :action => :edit
    end
  end

  def complete
    @response.complete!
  end

  def accept
    @response.accept!
  end

  def cancel
    @response.cancel!
  end

  def reject
    @response.reject!(params[:reject_because])
  end
end