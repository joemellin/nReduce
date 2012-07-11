class MentorsController < ApplicationController
  around_filter :record_user_action
  before_filter :login_required
  before_filter :load_requested_or_users_startup
  authorize_resource :startup
  before_filter :redirect_if_no_startup

  def index
    @mentor_elements = @startup.mentor_elements
  end

  def search
    authorize! :invite_mentor, @startup
    if !params[:search].blank?
      # sanitize search params
      params[:search].select{|k,v| [:name, :meeting_id, :industries].include?(k) }

      # save in session for pagination
      @search = session[:search] = params[:search]
    elsif !params[:page].blank?
      @search = session[:search]
    end

    @search ||= {}
    @search[:page] = params[:page] || 1

    # Have to pass context for block or else you can't access @search instance variable
    @search_results = User.search do |s|
      s.with :nreduce_mentor, true
      unless @search[:industries].blank?
        tag_ids = ActsAsTaggableOn::Tag.named_like_any_from_string(@search[:industries]).map{|t| t.id }
        # finds 
        s.with :industry_tag_ids, tag_ids unless tag_ids.blank?
      end
      unless @search[:skills].blank?
        tag_ids = ActsAsTaggableOn::Tag.named_like_any_from_string(@search[:skills]).map{|t| t.id }
        # finds 
        s.with :skill_tag_ids, tag_ids unless tag_ids.blank?
      end
      s.order_by :rating, :desc
      s.paginate :page => @search[:page], :per_page => 10
    end
    @ua = {:data => @search}

  end
end