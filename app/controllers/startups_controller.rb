class StartupsController < ApplicationController
  before_filter :login_required

  def new
    if current_startup.present?
      flash.keep
      redirect_to "/startup"
      return
    end

    @startup = Startup.new(:team_members => ["@#{current_auth.twitter.downcase}"])
  end

  def create
    if current_startup.present?
      flash.keep
      redirect_to "/startup"
      return
    end

    @startup = Startup.new
    @startup.attributes = startup_attributes
    @startup.team_members = (["@#{current_auth.twitter.downcase}"] + @startup.team_members.to_a).uniq

    # lets automatically set the single cofounder one
    @startup.agree4 = @startup.team_members.to_a.count > 1

    if @startup.save
      flash[:notice] = "Startup information has been saved. Thanks!"
      redirect_to "/thanks/startup"
    else
      render :new
    end
  end

  # show your team profile "dashboard"
  before_filter :startup_required, :only => [:show, :edit, :update]
  def show
    @startup = current_startup
  end

  # edit form for team profile
  def edit
    @startup = current_startup

  end

  # updates team profile
  def update
    @startup = current_startup
    @startup.attributes = startup_attributes
    if @startup.save
      flash[:notice] = "Startup information has been saved. Thanks!"
      redirect_to "/startup"
    else
      render :edit
    end
  end

  protected
  def startup_attributes
    attributes = params[:startup] || {}

    attributes.slice!(*[
      :name,
      :team_members_twitter,
      :location_name,
      :location_other,
      :agree1,
      :agree2,
      :agree3,
      :agree4,
      :agree5,
      :agree6,
      :agree7,
    ])

    attributes
  end
end