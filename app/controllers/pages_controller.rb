class PagesController < ApplicationController
  around_filter :record_user_action
  before_filter :login_required, :only => [:community_guidelines]
  
  def mentor
  end

  def investor
  end

  def community_guidelines
  end
end
