class CommentsController < ApplicationController
  before_filter :login_required
  
  def create
    @comment = Comment.new(params[:comment])
    @comment.user = current_user
    if @comment.save
      flash[:notice] = 'The comment has been added'
    else
      flash[:error] = 'The comment could not be added'
    end
    respond_to do |format|
      format.html { redirect_to @comment.checkin }
      format.js
    end
  end
  
  def edit
    @comment = Comment.find(params[:id])
    #@ua = {:action => UserAction.id_for('edit_comment'), :attachable => @comment}
    respond_to do |format|
      format.html
      format.js
    end
  end
  
  def cancel_edit
    @comment = Comment.find(params[:id])
    respond_to do |format|
      format.html { redirect_to @checkin }
      format.js
    end
  end
  
  def update
    @comment = Comment.find(params[:id])
    if @comment.update_attributes(params[:comment])
      flash[:notice] = 'The comment has been updated'
    else
      flash[:error] = 'The comment has been updated'
    end
    respond_to do |format|
      format.html { redirect_to @comment.checkin }
      format.js
    end
  end
  
  def destroy
    @comment = Comment.find(params[:id])
    if @comment.delete
      flash[:notice] = 'The commment has been deleted'
    else
      flash[:error] = 'The comment could not be deleted'
    end
    respond_to do |format|
      format.html { redirect_to @comment.checkin }
      format.js
    end
  end
end
