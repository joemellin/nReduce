class ApplicationController < ActionController::Base
  before_filter :block_ips
  protect_from_forgery

  protected

  def block_ips
    if request.remote_ip == '75.161.16.187'
      render :nothing => true
      return
    end
  end

  def registration_open?
    false
  end

  def login_required
    authenticate_user!
  end

  def admin_required
    if login_required
      if current_user.admin?
        return true
      else
        flash[:notice] = "You don't have admin access"
        redirect_to '/'
      end
    end
    return false
  end

  def current_startup_and_checkin_required
    @current_startup = current_user.startup if user_signed_in? and !current_user.startup.blank?
    if @current_startup.blank?
      redirect_to new_startup_path
      return false
    else
      # filters to see if they have checked in
      c = @current_startup.current_checkin
      return true if !c.blank? and c.completed?
      if !c.blank?
        if Checkin.in_after_time_window? and controller_name != 'checkins' and action_name != 'edit'
          flash[:notice] = "Finish your check-in for this week."
          redirect_to edit_checkin_path(c)
          return false
        end
      elsif Checkin.in_before_time_window? and controller_name != 'checkins' and action_name != 'new'
        flash[:notice] = "Start your check-in for this week."
        redirect_to new_checkin_path
        return false
      end
    end
    true
  end

  def current_startup_required
    @current_startup = current_user.startup if user_signed_in? and !current_user.startup.blank?
    if @current_startup.blank?
      redirect_to new_startup_path
      return false
    end
    true
  end
end
