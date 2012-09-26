class InstrumentsController < ApplicationController
  before_filter :login_required
  load_and_authorize_resource
  before_filter :load_obfuscated_startup
  load_and_authorize_resource :startup

  def new
    @instrument.startup = @startup
    respond_to do |format|
      format.js { render :action => :edit }
      format.html { render :nothing => true }
    end
  end

  def create
    @close_modal = true if @instrument.save
    respond_to do |format|
      format.js { render :action => :edit }
      format.html { render :nothing => true }
    end
  end
end
