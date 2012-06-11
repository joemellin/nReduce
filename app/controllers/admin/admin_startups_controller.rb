module Admin
  class AdminStartupsController < ApplicationController
    layout "admin"

    before_filter :admin_required

    def index
      @startups = Startup.order('created_at DESC')
      if params[:view].present?
        @startups = @startups.where(:location_name => /#{params[:view]}/i)
      end
    end

    def show
      @startup = Startup.by_id!(params[:id])
    end

    # mark a startup as approved
    def approve_startup

      startup = Startup.by_id!(params[:id])
      startup.approved = true
      startup.save!

      render :json => {
        :success => true
      }
    end

    # mark a startup as denied and mark it inactive
    def deny_startup
      startup = Startup.by_id!(params[:id])
      startup.approved = false
      startup.save!

      startup.destroy

      render :json => {
        :success => true
      }
    end

  end
end