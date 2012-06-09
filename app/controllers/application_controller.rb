class ApplicationController < ActionController::Base
  protect_from_forgery

  protected

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

  def startup_required
    @startup = current_user.startup if current_user and !current_user.startup.blank?
    if @startup.blank?
      redirect_to new_startup_path
      return
    end
    true
  end
end
