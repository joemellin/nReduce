class PagesController < ApplicationController
  around_filter :record_user_action
  before_filter :login_required, :only => [:community_guidelines]
  
  def mentor
  end

  def investor
  end

  def home
    @weekly_class = WeeklyClass.current_class
    #@demo_day = DemoDay.next_or_current
    @home = true
    if user_signed_in?
      redirect_to work_room_path
      return
    end
  end

  def community_guidelines
  end

  def nstar
    @rsvp = Rsvp.new
    @rsvp.demo_day_id = DemoDay.first.id unless DemoDay.first.blank?
    @rsvp.accredited = false
    if user_signed_in?
      @rsvp.email = current_user.email 
      @rsvp.user = current_user
    end
  end
end
