class ConversationsController < ApplicationController
  before_filter :login_required
  load_and_authorize_resource :except => [:index]

  def index
    load_users_and_startups_for_conversations
    if @conversations.present?
      @conversation = @conversations.first
      mark_conversation_as_read_for_current_user(@conversation)
    end
  end

  def show
    load_users_and_startups_for_conversations
    respond_to do |format|
      format.js
      format.html { render :action => :index }
    end
    # Mark conversation as read for this user
    mark_conversation_as_read_for_current_user(@conversation) if @conversation.present?
  end

  def new
    # When you start a message to someone on a startup - does it automatically include your co-founders? That doesn't make sense, kind of defeats the purpose of private
    # I think you should have to choose your recipients, and can always add more people to the message.
    @conversation.messages << Message.new(:from_id => current_user.id)
    # Right now no validation on ids
    @conversation.participant_ids = params[:participant_ids] if params[:participant_ids].present?
    respond_to do |format|
      format.js
      format.html { render :nothing => true }
    end
  end

  def create
    @conversation = Conversation.create(params[:conversation])
    if !@conversation.new_record?
      load_recent_conversations # from application controller
      respond_to do |format|
        format.js
      end
    else
      flash[:alert] = @conversation.errors.full_messages.join(', ')
      respond_to do |format|
        format.js { render :action => :new }
      end
    end
  end

  def add_message
    @conversation = Conversation.find(params[:id])
    @message = Message.new(params[:message])
    flash[:alert] = @message.errors.full_messages.join(', ') unless @message.save
    respond_to do |format|
      format.js
      format.html { render :nothing => true }
    end
  end

  def destroy
    cs = ConversationStatus.where(:user_id => current_user.id, :conversation_id => params[:id]).first
    if cs.trash!
      flash[:notice] = "The conversation has been moved to the trash."
    else
      flash[:alert] = "Sorry but that conversation couldn't be moved to the trash at this time."
    end
    redirect_to :action => :index
  end

  protected

  def mark_conversation_as_read_for_current_user(conversation)
    @conversation_statuses.each{|cs| cs.mark_as_read! if cs.conversation_id == conversation.id }
  end

  def load_users_and_startups_for_conversations
    # This is now loaded in application_controller on all actions
    #cvs = ConversationStatus.where(:user_id => current_user.id).with_folder(:inbox).includes(:conversation).order('conversations.updated_at DESC').limit(20)
    #@conversations = cvs.map{|cs| cs.conversation }

    @users_by_id = Hash.by_key(User.where(:id => @conversations.map{|c| c.participant_ids }.flatten), :id)
    #@startups_by_id = Hash.by_key(Startup.where(:id => @conversations.map{|c| c.startup_ids }.flatten), :id)
  end
end
