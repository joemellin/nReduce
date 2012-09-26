class MentorsController < ApplicationController
  before_filter :login_required
  before_filter :load_requested_or_users_startup

  def index
    # Just redirect current nreduce mentors to see list of mentors
    if current_user.roles?(:nreduce_mentor)
      redirect_to :action => :search
    else
      authorize! :see_mentor_page, current_user
      @mentor_elements = @startup.mentor_elements unless @startup.blank?
    end
    @mentors = User.with_roles(:nreduce_mentor)
  end

  def search
    authorize! :search_mentors, User
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

    # Cache number of startups they are connected to  - just grab all relationships startup to user
    @startups_per_user = Cache.get('startups_by_mentor', 1.hour){
      Relationship.startup_to_user.approved.group('connected_with_id').count
    }

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
      s.order_by :has_pic, :desc
      s.order_by :num_mentoring, :desc
      s.order_by :rating, :desc
      s.paginate :page => @search[:page], :per_page => 10
    end
  end

  def change_status
    authorize! :change_mentor_status, User
    current_user.roles << :nreduce_mentor if !params[:nreduce_mentor].blank?
    if current_user.save
      flash[:notice] = "Thank you! You are now listed as an nReduce mentor. Startups will contact you when they think there is a fit."
      redirect_to :action => :search
    else
      flash[:error] = "Your account couldn't be updated: #{current_user.errors.full_messages.join(', ')}."
      redirect_to :action => :index
    end
  end
end