class InvestorsController < ApplicationController

  before_filter :investor_required, :only => [:edit, :update]

  def new
    @investor = Investor.new
    @investor.twitter = current_auth.twitter if current_auth
  end

  def create
    @investor = Investor.new
    @investor.attributes = investor_attributes

    if @investor.save
      @investor.mailchimp!
      flash[:notice] = "Your information has been saved. Thanks!"
      redirect_to "/thanks/investor"
    else
      render :new
    end
  end

  def edit
    @investor = current_investor
  end

  def update
    @investor = current_investor

    # TODO: update
  end

  protected

  def investor_attributes
    attributes = params[:investor] || {}

    attributes.slice!(*[
      :name,
      :email,
      :twitter,
      :linkedin_url,
      :angellist_url,
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
