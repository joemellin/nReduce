require 'spec_helper'

describe UsersController do
  login_user

  it "should allow a user to search public startups" do
    get :show, :id => 'me'
    response.should render_template(:show)
  end
end
