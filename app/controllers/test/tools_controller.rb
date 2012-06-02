module Test
  class ToolsController < ApplicationController
    def test_alert
      flash[:alert] = params[:msg] || "Something didn't work"
      redirect_to "/"
    end

    def test_notice
      flash[:notice] = params[:msg] || "Successfully created..."
      redirect_to "/"
    end
  end
end