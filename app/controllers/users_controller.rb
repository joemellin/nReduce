class UsersController < ApplicationController
  #around_filter :record_user_action, :except => [:reset_hipchat_account]
  before_filter :login_required
  before_filter :load_user_if_me_or_current
  before_filter :load_obfuscated_user, :only => [:show, :edit, :change_password, :account_type, :update, :welcome, :seen_help_exchange_message]
  authorize_resource

  def index
    redirect_to '/'
  end

  def complete_account
  end

  def show
    # Load current invite if they have one  - don't search by email because that opens security hole where a user can sign up with an email they don't own and get invite - really should be verifying email
    if @user.id == current_user.id
      @current_invite = Invite.not_accepted.where(:to_id => current_user.id).first
      @current_invite = nil if @current_invite and !@current_invite.active?
    elsif @user.roles?(:nreduce_mentor)
      @can_invite_as_mentor = (can? :invite_mentor, current_user.startup) unless current_user.startup_id.blank?
    end
  end

  def account_type
    @hide_background_image = true
    # Save account type if post
    if request.post?
      current_user.set_account_type(params[:roles], !params[:reset].blank?) unless params[:roles].blank?
      if current_user.save
        redirect_to '/'
        return
      end
    end
  end

  def edit
    @user.intro_video = ViddlerVideo.new if @user.intro_video.blank?
    @profile_elements = @user.profile_elements
    @profile_completeness_percent = (@user.profile_completeness_percent * 100).round
  end

  def update
    @user.profile_fields_required = true
    if @user.update_attributes(params[:user])
      #flash[:notice] = "Your account has been updated!"
      respond_to do |format|
        format.js { render :action => :update }
        format.html { redirect_to :action => :show }
      end
    else
      if params[:complete_account].to_s == 'true'
        render :action => :complete_account
      else
        respond_to do |format|
          format.js { render :action => :update }
          format.html { render :action => :edit }
        end
      end
    end
  end
  
  def chat
    @user.generate_hipchat! unless @user.hipchat?
  end

  def reset_hipchat_account
    if @user.reset_hipchat_account!
      flash[:notice] = "Your HipChat account has been reset, please try logging in again."
    else
      flash[:alert] = "Sorry but your HipChat account could not be reset. Please contact josh@nreduce.com"
    end
    redirect_to :action => :chat
  end

  def welcome
    # For now require that we manually approve users so don't finish account setup
    if request.post? and params[:i]
      current_user.setup_complete!
      redirect_to '/'
      return
    end
    @conversion = true
  end

  def change_password
    @change_password = true
    render 'devise/registrations/edit'
  end

  protected

  def load_obfuscated_user
    begin
      @user ||= User.find_by_obfuscated_id(params[:id])
    rescue ActiveRecord::RecordNotFound
      redirect_to '/'
      return
    end
  end

  def load_user_if_me_or_current
    @user = current_user if params[:id].blank?
    @user = current_user if params[:id] == 'me'
    
  end
end
