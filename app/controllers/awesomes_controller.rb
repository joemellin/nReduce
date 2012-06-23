class AwesomesController < ApplicationController
  around_filter :record_user_action, :except => [:cancel_edit]
  before_filter :login_required

  def create
    @awesome = Awesome.new({:awsm_id => params[:awsm_id], :awsm_type => params[:awsm_type]})
    @awesome.user_id = current_user.id
    @success = true if @awesome.save
    respond_to do |format|
      format.html { redirect_to @awesome.awsm }
      format.js { render :action => :button }
    end
  end
  
  def destroy
    @awesome = Awesome.find(params[:id])
    @success = true if current_user.id == @awesome.user_id and @awesome.destroy
    respond_to do |format|
      format.html { redirect_to @awesome.awsm }
      format.js { render :action => :button }
    end
  end

end
