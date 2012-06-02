module Admin
  class AdminSignupsController < ApplicationController
    layout "admin"

    before_filter :partner_required

    def index
      @signups = User.all

      if params[:view].blank? or params[:view] == "startups"
        @signups = @signups.where(:startup => true)
      elsif params[:view] == "mentors"
        @signups = @signups.where(:mentor => true)
      elsif params[:view] == "spectators"
        @signups = @signups.where(:mentor => false, :startup => false)
      elsif params[:view] == "all"
        @signups = @signups.all
      end

    end

  end
end