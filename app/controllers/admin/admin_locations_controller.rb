module Admin
  class AdminLocationsController < ApplicationController
    layout "admin"

    before_filter :partner_required

    def index
      @locations = Location.ordered
    end

    def new
      @location = Location.new(:order => Location.ordered.last.try(:order).to_i + 1)
    end

    # quick edit action
    def create
      @location = Location.new(params[:location])

      if @location.save
        flash[:notice] = "Location created."
        redirect_to "/admin/locations"
      else
        render :new
      end
    end

    def edit
      @location = Location.by_id!(params[:id])
    end

    def update
      @location = Location.by_id!(params[:id])

      if @location.update_attributes(params[:location])
        flash[:notice] = "Location has been updated"
        redirect_to "/admin/locations"
      else
        render :edit
      end

    end

    def destroy
      @location = Location.by_id!(params[:id])
      @location.destroy

      flash[:notice] = "Location deleted"
      redirect_to "/admin/locations"
    end

  end
end