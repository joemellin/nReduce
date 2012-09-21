class PostsController < ApplicationController
  before_filter :login_required
  load_and_authorize_resource :comment, :parent => false

  def index
    @comments = Comment.posts.limit(30).all
    @hottest_post = Comment.hottest_post_for_time(Time.now)
  end

  def show
    authorize! :read_post, Comment
    @comments = @comment.children.includes(:user).arrange(:order => 'created_at DESC') # arrange in nested order
  end
end
