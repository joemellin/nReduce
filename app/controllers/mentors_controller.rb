class MentorsController < ApplicationController
  around_filter :record_user_action
  before_filter :login_required
  before_filter :load_requested_or_users_startup
  authorize_resource :startup
  before_filter :redirect_if_no_startup

  def index
    @mentor_elements = @startup.mentor_elements
  end
end