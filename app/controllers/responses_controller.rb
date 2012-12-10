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
      redirect_to [@request, @response]
    else
      render :action => :edit
    end
  end

  def edit

  end

  def update
    if @response.can_be_completed? ? @response.complete! : @response.save
      redirect_to [@request, @response]
    else
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