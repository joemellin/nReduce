class RsvpsController < ApplicationController
  load_and_authorize_resource

  def create
    if @rsvp.save
      flash[:notice] = "Thanks! We'll be in touch as the date nears for demo day."
      redirect_to home_path
    else
      flash[:alert] = @rsvp.errors.full_messages.join(', ') + '.'
      redirect_to :controller => 'pages', :action => 'nstar'
    end
  end
end
