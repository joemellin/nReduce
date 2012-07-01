class SignupController < ApplicationController
  # post signups from the static web app
  def create
    # for duplicate emails, just return success
    if params[:email].present? and User.where(:email => params[:email]).count > 0
      render :json => {
        :success => true
      }
      return
    end

    # create user
    user = User.new
    user.name = params[:name]
    user.validate_name = true

    user.email = params[:email]
    user.validate_email = true

    user.spectator = true
    user.mentor = params[:selectedTypes].to_a.include?("mentor")
    user.startup = params[:selectedTypes].to_a.include?("startup")

    results = user.save

    user.send_startup_intro_email!

    render :json => {
      :success => results,
      :errors => user.errors,
    }
  end

end