class QuestionsController < ApplicationController
  #before_filter :only_allow_in_staging
  before_filter :login_required, :except => [:index]
  before_filter :load_obfuscated_startup_nested
  load_and_authorize_resource :startup
  load_and_authorize_resource :through => :startup
  #protect_from_forgery :except => [:index]

  def index
    if params[:last].present?
      begin
        last_polled_at = Time.parse(params[:last])
      rescue
        last_polled_at = nil
      end
    else
      last_polled_at = nil
    end
    questions_exist = load_questions_for_startup(@startup, last_polled_at)
    (render(:nothing => true) && return) unless questions_exist
    respond_to do |format|
      format.js { render :action => :list }
      format.html { render :nothing => true }
    end
  end

  def new
  end

  def create
    @question.user = current_user
    @question.startup = @startup
    @created_question = @question
    if @question.save
      load_questions_for_startup(@startup)
        # JS will render page that redirects to url
      respond_to do |format|
        format.js { render :action => :list }
        format.html { render :nothing => true }
      end
    else
      respond_to do |format|
        format.js { render :action => :edit }
        format.html { render :nothing => true }
      end
    end
  end

  # Show your support for a question
  def support
    @question.add_supporter!(current_user)
    respond_to do |format|
      format.js
      format.html { render :nothing => true }
    end
  end

  # Indicate you've answered
  def answer
    @question.answer!
    load_questions_for_startup(@startup)
    respond_to do |format|
      format.js { render :action => :list }
      format.html { render :nothing => true }
    end
  end
end
