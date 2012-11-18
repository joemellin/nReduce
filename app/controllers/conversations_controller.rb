class ConversationsController < ApplicationController
  before_filter :login_required
  load_and_authorize_resource :except => [:index]

  def index
    load_all_recent_conversations
  end

  def show
    load_all_recent_conversations
  end

  def new

  end

  def create
    
  end

  protected

  def load_all_recent_conversations
    @conversations = Conversation.join('conversation_statuses ON conversation_statuses.conversation_id = conversations.id').where(['conversation_statuses.user_id = ?', current_user.id]).order('conversations.updated_at DESC').limit(20)
    @users_by_id = Hash.by_key(User.where(:id => @conversations.map{|c| c.user_ids }.flatten), :id)
    @startups_by_id = Hash.by_key(Startup.where(:id => @conversations.map{|c| c.startup_ids }.flatten), :id)
  end
end
