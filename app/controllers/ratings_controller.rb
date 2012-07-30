class RatingsController < ApplicationController
  around_filter :record_user_action, :except => [:cancel_edit]
  before_filter :login_required
  load_and_authorize_resource

  def create
    if @rating.save
      flash[:notice] = "Your rating has been stored!"
    else
      flash[:alert] = "Sorry, your rating could not be stored."
    end
    respond_to do |format|
      format.js
      format.html { render :nothing => true }
    end
  end
end
