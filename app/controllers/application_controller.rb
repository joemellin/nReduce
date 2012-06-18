class ApplicationController < ActionController::Base
  #before_filter :block_ips
  protect_from_forgery

  protected

  # use an around_filter
  def record_user_action
    return true if @ua
    started = Time.now
    yield
    begin
      #if Rails.env == 'production'
        @ua ||= {}
        # for user tracking
        elapsed = Time.now - started
        @ua[:action] = UserAction.id_for("#{controller_name}_#{action_name}")
        @ua[:ip] = request.remote_ip
        @ua[:time_taken] = elapsed
        @ua[:browser] = request.env['HTTP_USER_AGENT']
        @ua[:user_id] ||= current_user.id if user_signed_in?
        @ua[:created_at] = Time.now
        @ua[:url_path] = request.env['REQUEST_PATH']
        user_action = UserAction.new(@ua)
        user_action.save!
    #  end
    rescue
      # do nothing
    end
  end


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

  
  def meeting_organizer_required
    @meeting = Meeting.find(params[:meeting_id]) unless params[:meeting_id].blank?
    @meeting ||= Meeting.find(params[:id]) unless params[:id].blank?
    return false if @meeting.blank?
    if (@meeting.organizer_id != current_user.id) and !current_user.admin?
      flash[:alert] = "You don't have permission to mesage attendees"
      redirect_to @meeting
      return false
    else
      return true
    end
  end
end
