class PagesController < ApplicationController
  around_filter :record_user_action, :only => [:home]
  before_filter :run_ab_test, :only => [:home]
  before_filter :login_required, :only => [:community_guidelines, :tutorial]

  def mentor
  end

  def investor
  end

  def testemail
    render :layout => false
  end

  def home
    @weekly_class = WeeklyClass.current_class # to load map of active users
    #@demo_day = DemoDay.where(:day => Date.today).first
    @home = true
    if user_signed_in?
      redirect_to current_user.entrepreneur? ? work_room_path : board_room_path
      return
    end

    render :action => "home_a"
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
