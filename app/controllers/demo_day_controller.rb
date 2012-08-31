class DemoDayController < ApplicationController
  def index
    @demo_day = DemoDay.first
  end

    # Show a specific company
  def show
    @demo_day = DemoDay.first
    @startup = Startup.find_by_obfuscated_id(params[:id])
    @tokbox = true
    @questions = @startup.questions.unanswered.ordered
    @current_question = @questions.shift
    @question = Question.new(:startup => @startup)
    redirect_to :action => :index && return unless @demo_day.startup_ids.include?(@startup.id)
  end
end
