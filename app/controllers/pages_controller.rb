class PagesController < ApplicationController
  around_filter :record_user_action
  before_filter :login_required, :only => [:community_guidelines]
  
  def mentor
  end

  def investor
  end

  def home
    if user_signed_in?
      redirect_to relationships_path
      return
    end
  end

  def community_guidelines
  end

  def nstar
    @rsvp = Rsvp.new
    @rsvp.demo_day_id = DemoDay.first.id unless DemoDay.first.blank?
    @rsvp.accredited = false
    @rsvp.user = current_user if user_signed_in?
  end
end
