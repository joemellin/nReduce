class NotificationsController < ApplicationController
  before_filter :login_required

  def index
    @notifications = current_user.notifications.unread.ordered.all
    if @notifications.size == 0
      @notifications = current_user.notifications.ordered.limit(20).all
    elsif @notifications.size < 20
      @notifications += current_user.notifications.read.ordered.limit(20 - @notifications.size).all
    end
    current_user.mark_all_notifications_read
  end
end
