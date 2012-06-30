class AwesomesController < ApplicationController
  around_filter :record_user_action, :except => [:cancel_edit]
  before_filter :login_required
  load_and_authorize_resource

  def create
    @awesome.user_id = current_user.id
    @success = true if @awesome.save
    respond_to do |format|
      format.html { redirect_to @awesome.awsm }
      format.js { render :action => :button }
    end
  end
  
  def destroy
    @success = true if @awesome.destroy
    respond_to do |format|
      format.html { redirect_to @awesome.awsm }
      format.js { render :action => :button }
    end
  end
end
