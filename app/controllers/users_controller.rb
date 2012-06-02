class UsersController < ApplicationController

  before_filter :login_required, :only => [:edit_rsvp, :update_rsvp, :show]

  def rsvp_redirect
    token_user = lookup_user_by_token(params[:user_token])
    if token_user.present?
      token_user.confirm!
      session[:token_user] = token_user.id.to_s
    end

    redirect_to "/rsvp/edit"
  end

  def edit_rsvp
    @auth = current_auth

    # prepopulate email if present
    if @auth.email.blank? and token_user.present?
      @auth.email = token_user.email
    end

    if @auth.matching_startup.blank?
      flash[:notice] = "Not currently associated with a startup. Register one now?"
      redirect_to "/"
      return
    end

    # TODO
  end

  def update_rsvp
    @auth = current_auth

    @auth.email_required = true
    @auth.location_required = true

    @auth.email = params[:authentication][:email]
    @auth.phone_number = params[:authentication][:phone_number]
    @auth.location_id = params[:authentication][:location_id]
    @auth.rsvp_notes = params[:authentication][:rsvp_notes]

    if @auth.save
      @auth.mailchimp!

      flash[:notice] = "Thanks, we've got your RSVP! We'll email you the details once they're confirmed."
      redirect_to "/"
    else
      render :edit_rsvp
    end
  end

  def confirm
    token_user = lookup_user_by_token(params[:user_token])

    if token_user.present?
      token_user.confirm!
      session[:token_user] = token_user.id.to_s

      flash[:notice] = "Email confirmed. Thanks!"

      if token_user.startup?
        redirect_to "/startups/new"
      elsif token_user.mentor?
        redirect_to "/thanks/mentor"
      elsif token_user.spectator?
        redirect_to "/thanks/spectator"
      end
    else
      flash[:alert] = "Unable to find a matching user"
      redirect_to "/"
    end
  end

  def show
    @auth = current_auth
  end

  protected

  def lookup_user_by_token(token)
    return unless token.present?

    User.where(:token => token).first
  end
end
