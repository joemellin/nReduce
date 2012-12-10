class PaymentsController < ApplicationController
  before_filter :require_ssl
  before_filter :login_required
  before_filter :load_requested_or_users_startup
  load_and_authorize_resource 

  def new
  end

  def create
    @payment.user = current_user
    if @payment.save
      redirect_to @payment.account
    else
      render :action => :edit
    end
  end

  def edit

  end

  def update
    if @payment.save
      redirect_to @payment
    else
      render :action => :edit
    end
  end

  def cancel
    if @payment.cancel!
      flash[:notice] = "Your purchase has been canceled"
    else
      flash[:error] = "Sorry but your purchase couldn't be canceled at this time"
    end
    redirect_to @payment.account
  end
end
