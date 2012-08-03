class VideosController < ApplicationController
  around_filter :record_user_action
  before_filter :login_required
  load_and_authorize_resource

  def record
    @viddler = Video.new(:type => 'ViddlerClient')
    @screenr = Video.new(:type => 'Screenr')
  end

  def show
  end

  def create
    @video.user = current_user
    if @video.save
      redirect_to @video
    else
      flash[:alert] = "Sorry but your video could not be saved. Please try again."
      redirect_to record_videos_path
    end
  end
end
