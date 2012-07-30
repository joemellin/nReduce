class InvestorsController < ApplicationController
  around_filter :record_user_action
  before_filter :login_required
  before_filter :investor_required

  def index
  end

  protected

  def investor_required
    authorize! :see_investors, User
  end
end
