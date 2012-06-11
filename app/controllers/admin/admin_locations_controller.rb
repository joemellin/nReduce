module Admin
  class AdminMeetingsController < ApplicationController
    layout "admin"

    before_filter :admin_required

    def index
      @meetings = Meeting.ordered
    end

    def new
      @meeting = Meeting.new(:order => Meeting.ordered.last.try(:order).to_i + 1)
    end

    # quick edit action
    def create
      @meeting = Meeting.new(params[:Meeting])

      if @meeting.save
        flash[:notice] = "Meeting created."
        redirect_to "/admin/Meetings"
      else
        render :new
      end
    end

    def edit
      @meeting = Meeting.by_id!(params[:id])
    end

    def update
      @meeting = Meeting.by_id!(params[:id])

      if @meeting.update_attributes(params[:Meeting])
        flash[:notice] = "Meeting has been updated"
        redirect_to "/admin/meetings"
      else
        render :edit
      end

    end

    def destroy
      @meeting = Meeting.by_id!(params[:id])
      @meeting.destroy

      flash[:notice] = "Meeting deleted"
      redirect_to "/admin/meetings"
    end

  end
end