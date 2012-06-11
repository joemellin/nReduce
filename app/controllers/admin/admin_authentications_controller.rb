module Admin
  class AdminAuthenticationsController < ApplicationController
    layout "admin"

    before_filter :admin_required

    def index
      @authentications = Authentication.all.desc(:partner)
    end


    def set_partner
      auth = Authentication.by_id!(params[:id])
      auth.partner = (params[:partner] == "true")
      auth.save!

      render :json => {
        :success => true
      }
    end


  end
end