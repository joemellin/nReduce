module Admin
  class AdminRsvpsController < ApplicationController
    layout "admin"

    before_filter :partner_required

    def index
      @authentications = Authentication.all

      # setup location hash
      @location_names = {}
      Location.all.each do |location|
        @location_names[location.id] = location.name
      end

      # filter by location
      if params[:location].present?
        @location = Location.by_id!(params[:location])
        @authentications = @authentications.where(:location_id => @location.id)
      end


      @authentications = @authentications.select{|a| a.rsvped? }
    end

  end
end
