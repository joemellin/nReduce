class RsvpsController < ApplicationController
  load_and_authorize_resource

  def create
    if @rsvp.save
      flash.now[:notice] = "Thanks! We'll be in touch as the date nears for the demo day."
      render :show
    else
      flash[:alert] = @rsvp.errors.full_messages.join(', ') + '.'
      redirect_to :controller => 'pages', :action => 'nstar'
    end
  end
end
