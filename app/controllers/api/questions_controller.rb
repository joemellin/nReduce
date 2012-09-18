class Api::QuestionsController < ApiController
  #before_filter :load_obfuscated_startup_nested
  #load_and_authorize_resource :startup
  #load_and_authorize_resource :through => :startup
  respond_to :json

  def index
    @questions = Question.first(20)
    respond_with(@questions)
  end
end