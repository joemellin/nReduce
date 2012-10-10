class InvitesController < ApplicationController
  before_filter :login_required, :except => :accept
  before_filter :load_obfuscated_startup, :only => :create
  load_and_authorize_resource :startup, :only => :create
  load_and_authorize_resource :only => :destroy

  def create
    if @startup
      @invite = Invite.new(:startup_id => @startup.id)
    elsif current_user.admin?
      @invite = Invite.new
    end
    authorize! :create, @invite
    @invite.attributes = params[:invite]
    @invite.save
    if @invite.new_record?
      flash[:alert] = @invite.errors.full_messages.join(', ') + '.'
    else
      flash[:notice] = "Your invite has been sent to #{@invite.to_name}"
    end
    if @startup.blank? and current_user.admin?
      redirect_to admin_mentors_path
    else
      # They came from weekly class invite
      if @invite.weekly_class && !current_user.account_setup?
        redirect_to @invite.weekly_class
      else # They invited from startup edit page
        redirect_to edit_startup_path(@startup)
      end
    end
  end

  def destroy
    if @invite.destroy
      if @invite.to_id == current_user.id
        flash[:notice] = "The invite has been removed."
      else
        flash[:notice] = "#{@invite.email} is no longer invited to join your team."
        end
    else
      flash[:alert] = "Sorry but invite could not be removed at this time."
    end
    if @invite.to_id == current_user.id
      redirect_to current_user
    else
      respond_to do |format|
        format.js
        format.html { redirect_to edit_startup_path(@startup) }
      end
    end
  end
  
  def accept
    @invite = Invite.find_by_code(params[:id])
    if @invite.nil?
      flash[:alert] = "Sorry but that invite has been canceled."
      redirect_to '/'
      return
    end
    # see if the email has been registered
    if @invite && @invite.active?
      u = User.where(:email => @invite.email).first
      if u.blank? # no user account - ask them to register
        sign_out(current_user) if user_signed_in?
        session[:invite_id] = @invite.id
        session[:sign_in_up_email] = @invite.email
        redirect_to new_registration_path(:user)
      else # they have an account
        # get them to login if not signed in or email doesn't match current user
        if !user_signed_in?
          sign_out(current_user)
          flash[:alert] = "That invite is for #{@invite.email} - please sign in with that account." if user_signed_in? and current_user.email != u.email
          session[:sign_in_up_email] = @invite.email
          session[:invite_id] = @invite.id # make sure it's set
          redirect_to new_session_path(:user)
        else # they are signed in - assign invite to this account (don't check email)
          session[:invite_id] = @invite.id
          if accept_invite_for_user(current_user)
            flash[:notice] = "Thanks for joining!"
            if @invite.startup.present?
              redirect_to startup_path(@invite.startup)
            else
              redirect_to '/'
            end
          else
            flash[:alert] = "Oops you couldn't be added to that team..."
            redirect_to root_path
          end
        end
      end
      #@ua = {:attachable => @invite}
    else
      if !current_user.blank? and @invite.to_id == current_user.id
        flash[:notice] = "You have already accepted that invite."
      else
        flash[:alert] = "Sorry, that is not a valid invite.  Please make sure you copy the full url."
      end
      redirect_to root_path
    end
  end
end
