class PaymentsController < ApplicationController
  before_filter :require_ssl
  before_filter :login_required

end
