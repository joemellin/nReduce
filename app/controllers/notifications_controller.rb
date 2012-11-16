class NotificationsController < ApplicationController
  before_filter :login_required
  load_and_authorize_resource :through => :current_user

  def index
    @notifications = @notifications.unread.ordered.all
    if @notifications.size == 0
      @notifications = current_user.notifications.ordered.limit(20).all
    elsif @notifications.size < 20
      @notifications += current_user.notifications.read.ordered.limit(20 - @notifications.size).all
    end
    current_user.mark_all_notifications_read
  end

  def mark_all_as_read
    current_user.mark_all_notifications_read
    render :nothing => true
  end
end
