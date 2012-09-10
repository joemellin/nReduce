class WeeklyClassesController < ApplicationController
  before_filter :login_required
  load_and_authorize_resource

  def show
    @waiting_for_next_class = true
    @stats = WeeklyClass.top_stats
  end
end
