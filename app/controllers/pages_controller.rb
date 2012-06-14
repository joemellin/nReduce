class PagesController < ApplicationController
  around_filter :record_user_action
  
  def mentor
  end

  def investor
  end
end
