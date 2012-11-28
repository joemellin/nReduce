class ConversationsController < ApplicationController
  before_filter :login_required
  load_and_authorize_resource :except => [:index]

  def index
    load_users_and_startups_for_conversations
    mark_all_conversations_for_current_user_as_seen
    if @conversations.present?
      @conversation = @conversations.first
      mark_conversation_as_read_for_current_user(@conversation)
    end
  end

  def show
    load_users_and_startups_for_conversations
    mark_all_conversations_for_current_user_as_seen
    respond_to do |format|
      format.js
      format.html { render :action => :index }
    end
    # Mark conversation as read for this user
    mark_conversation_as_read_for_current_user(@conversation) if @conversation.present?
  end

  def new
    @conversation.team_to_team = true # All messages by default right now are team to team
    @new_message = true
    load_users_and_startups_for_conversations unless request.xhr?
    # When you start a message to someone on a startup - need it to automatically include your co-founders?
    @conversation.messages << Message.new(:from_id => current_user.id)
    # Right now no validation on ids
    if params[:participant_ids].present?
      @conversation.participant_ids = params[:participant_ids].split('|') 
    else
      @conversation.participant_ids = [current_user.id]
    end
    if params[:startup_id].present?
      s = Startup.find_by_obfuscated_id(params[:startup_id])
      @conversation.to = "#{s.name} (Team to Team Message)"
      @conversation.to_entity = "startup_#{s.id}"
    end
    respond_to do |format|
      format.js
      format.html { render :action => :index }
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

  def search_startups
    if !current_user.entrepreneur? || params[:query].blank? || params[:query].present? && params[:query].size < 1
      render :json => [] 
      return
    end
    # Autocomplete for anyone they're connected to + nReduce
    connected_to_ids = current_user.startup.connected_to_ids('Startup') + [Startup.nreduce_id]
    #users = User.select('id, name').where(['name LIKE ?', "#{params[:query]}%"]).where("startup_id IN (#{connected_to_ids.join(',')})").limit(10)
    startups = Startup.select('id, name').where(['name LIKE ?', "#{params[:query]}%"]).where("id IN (#{connected_to_ids.join(',')})").order(:name).limit(20)
    #render :json => (users + startups).sort{|a,b| a.name <=> b.name }.map{ |e| e.is_a?(User) ? {:name => e.name, :id => "user_#{e.id}"} : {:name => "#{e.name} (Team to Team Message)", :id => "startup_#{e.id}" } }
    render :json => startups.map{|s| { :name => "#{s.name} (Team to Team Message)", :id => "startup_#{s.id}" } }
  end

  def mark_all_as_seen
    mark_all_conversations_for_current_user_as_seen
    render :nothing => true
  end

  protected

  def mark_all_conversations_for_current_user_as_seen
    current_user.conversation_statuses.unseen.each{|cs| cs.mark_as_seen! }
  end

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
