class PostsController < ApplicationController
  before_filter :login_required
  load_and_authorize_resource :comment, :parent => false

  def index
    @comments = Comment.posts.limit(30).all
  end

  def show
    authorize! :read_post, Comment
    @comments = @comment.children.includes(:user).arrange(:order => 'created_at DESC') # arrange in nested order
  end
end
