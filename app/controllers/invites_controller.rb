class InvitesController < ApplicationController
  around_filter :record_user_action
  before_filter :login_required, :except => :accept
  load_and_authorize_resource :startup, :only => :create
  load_and_authorize_resource :invite, :through => :startup, :only => :create
  load_and_authorize_resource :only => :destroy

  def create
    @invite.save
    if @invite.new_record?
      flash[:alert] = @invite.errors.full_messages.join(', ') + '.'
    else
      flash[:notice] = "Your invite has been sent to #{@invite.email}"
    end
    redirect_to edit_startup_path(@startup)
  end

  def destroy
    if @invite.destroy
      if @invite.to_id == current_user.id
        flash[:notice] = "The invite has been declined."
      else
        flash[:notice] = "#{@invite.email} is no longer invited to join your team."
        end
    else
      flash[:alert] = "Sorry but invite could not be removed at this time."
    end
    if @invite.to_id == current_user.id
      redirect_to current_user
    else
      redirect_to edit_startup_path(@startup)
    end
  end
  
  def accept
    @invite = Invite.find_by_code(params[:id])
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
        if !user_signed_in? or (user_signed_in? and current_user.email != u.email)
          sign_out(current_user) if user_signed_in?
          flash[:alert] = "That invite is for #{@invite.email} - please sign in with that account." if user_signed_in? and current_user.email != u.email
          session[:sign_in_up_email] = @invite.email
          session[:invite_id] = @invite.id # make sure it's set
          redirect_to new_session_path(:user)
        else # they are signed in as correct user
          session[:invite_id] = @invite.id
          if accept_invite_for_user(current_user)
            flash[:notice] = "You have been added to the #{@invite.startup.name} team!"
            redirect_to startup_path(@invite.startup)
          else
            flash[:alert] = "Oops you couldn't be added to that team..."
            redirect_to root_path
          end
        end
      end
      @ua = {:attachable => @invite}
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
