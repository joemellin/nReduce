class CommentsController < ApplicationController
  before_filter :login_required
  load_and_authorize_resource :comment

  def create
    @comment.user = current_user
    if @comment.save
      flash[:notice] = @comment.original_post? ? 'Your post has been created' : 'The comment has been added'
    else
      flash[:alert] = "Your #{@comment.original_post? ? 'post' : 'comment'} could not be added: #{@comment.errors.full_messages.join(', ')}."
    end
    #@ua = {:attachable => @comment}
    respond_to do |format|
      format.html { redirect_to @comment.original_post? ? post_path(@comment) : @comment.checkin }
      format.js
    end
  end
  
  def edit
    #@ua = {:attachable => @comment}
    respond_to do |format|
      format.html
      format.js
    end
  end

    # Render form to create a comment reply
  def reply_to
    @comment = Comment.new(:parent_id => @comment.id, :checkin_id => @comment.checkin_id)
    respond_to do |format|
      format.html { render :nothing => true }
      format.js
    end
  end
  
  def cancel_edit
    respond_to do |format|
      format.html { redirect_to @comment.original_post? ? post_path(@comment) : @comment.checkin }
      format.js
    end
  end
  
  def update
    if @comment.update_attributes(params[:comment])
      flash[:notice] = 'The comment has been updated'
    else
      flash[:alert] = 'The comment has been updated'
    end
    respond_to do |format|
      format.html { redirect_to @comment.checkin_id.present? ? @comment.checkin : post_path(@comment) }
      format.js
    end
  end
  
  def destroy
    #@ua = {:attachable => @comment}
    if @comment.safe_destroy
      flash[:notice] = 'The commment has been deleted'
    else
      flash[:alert] = 'The comment could not be deleted'
    end
    respond_to do |format|
      format.html { redirect_to @comment.checkin_id.present? ? @comment.checkin : post_path(@comment) }
      format.js
    end
  end
end
