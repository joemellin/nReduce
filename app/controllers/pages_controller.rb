class PagesController < ApplicationController
  before_filter :run_ab_test, :only => [:home]
  around_filter :record_user_action, :only => [:home]
  before_filter :login_required, :only => [:community_guidelines, :tutorial]

  def mentor
  end

  def investor
  end

  def home
    @weekly_class = WeeklyClass.current_class
    #@demo_day = DemoDay.where(:day => Date.today).first
    @home = true
    if user_signed_in?
      redirect_to current_user.entrepreneur? ? work_room_path : board_room_path
      return
    end
  end

  def community_guidelines
  end

  def tutorial
  end

  def coworking_location
    respond_to do |format|
      format.js
    end
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
