class VideosController < ApplicationController
  #around_filter :record_user_action
  before_filter :login_required
  load_and_authorize_resource

  def record
    @recording_video = true
    @viddler = Video.new(:type => 'ViddlerVideo')
    @screenr = Video.new(:type => 'Screenr')
  end

  def show
  end

  def create
    @video.user = current_user
    if @video.save
      redirect = @video
    else
      flash[:alert] = "Sorry but your video could not be saved. Please try again."
      redirect = record_videos_path
    end
    @replace_form = true
    respond_to do |format|
      format.js { render :action => 'edit' }
      format.html { redirect_to redirect }
    end
  end

  def edit

  end
end
