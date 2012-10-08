class RatingsController < ApplicationController
  #around_filter :record_user_action, :only => [:create]
  before_filter :login_required
  before_filter :load_obfuscated_startup_nested
  load_and_authorize_resource :startup
  load_and_authorize_resource :through => :startup
  
  def index
    @ratings = Rating.includes(:user).ordered.all #@ratings.includes(:user).ordered
    @weakest_element_data = Rating.chart_data_from_ratings(@ratings, :weakest_element)
    @contact_in_data = Rating.chart_data_from_ratings(@ratings, :contact_in)
  end

  def new
    @rating.interested = params[:interested] unless params[:interested].blank?
    @rating.startup = @startup
    respond_to do |format|
      format.js { render :action => :edit }
      format.html { render :nothing => true }
    end
  end

  def create
    @rating.user = current_user
    if @rating.save
      #flash[:notice] = "Your rating has been stored!"
      # They are done rating startups
      if params[:commit].match(/stop/i) != nil
        @redirect_to = investors_path
      else # They want to continue
        # Check if they are above their limit
        if current_user.can_connect_with_startups?
          @redirect_to = show_startup_investors_path
        else
          flash[:alert] = "You've already contacted a startup this week, please come back later or upgrade your account to connect with more startups."
          @redirect_to = investors_path
        end
      end
      # JS will render page that redirects to url
      respond_to do |format|
        format.js { render 'layouts/redirect_to' }
        format.html { redirect_to @redirect_to }
      end
    else
      logger.info @rating.inspect
      respond_to do |format|
        format.js { render :action => :edit }
        format.html { render :nothing => true }
      end
    end
  end
end
