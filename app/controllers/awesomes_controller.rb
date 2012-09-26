class AwesomesController < ApplicationController
  before_filter :login_required
  load_and_authorize_resource

  def create
    # Have to populate awesome manually becuase it comes from a post link
    @awesome.awsm_type = params[:awsm_type] unless params[:awsm_type].blank?
    @awesome.awsm_id = params[:awsm_id] unless params[:awsm_id].blank?
    @awesome.user_id = current_user.id
    @success = true if @awesome.save
    respond_to do |format|
      format.html { redirect_to '/' }
      format.js { render :action => :button }
    end
  end
  
  def destroy
    @success = true if @awesome.destroy
    respond_to do |format|
      format.html { redirect_to '/' }
      format.js { render :action => :button }
    end
  end
end
