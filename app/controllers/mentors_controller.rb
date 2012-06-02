class MentorsController < ApplicationController

  before_filter :mentor_required, :only => [:edit, :update]

  def new
    @mentor = Mentor.new
    @mentor.twitter = current_auth.twitter if current_auth
  end

  def create
    @mentor = Mentor.new
    @mentor.attributes = mentor_attributes

    if @mentor.save
      @mentor.mailchimp!
      flash[:notice] = "Your information has been saved. Thanks!"
      redirect_to "/thanks/mentor"
    else
      render :new
    end
  end

  def edit
    @mentor = current_mentor
  end

  def update
    @mentor = current_mentor

    # TODO: update
  end

  protected

  def mentor_attributes
    attributes = params[:mentor] || {}

    attributes.slice!(*[
      :name,
      :email,
      :twitter,
      :phone_number,
      :linkedin_url,
      :angellist_url,
      :other_urls,
      :topic,
      :topic_describe,
      :agree1,
      :agree2,
      :agree3,
      :agree4,
      :agree5,
      :agree6,
      :agree7,
    ])

    attributes[:twitter] = attributes[:twitter].to_s.gsub("@", "").strip
    attributes[:twitter] = "@#{attributes[:twitter]}" if attributes[:twitter].present?

    attributes
  end

end
