require 'spec_helper'

describe StartupsController do
  login_user_with_startup

  it "should allow a user to search public startups" do
    get :search
    response.should render_template(:search)
  end
end
