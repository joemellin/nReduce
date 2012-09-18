module DemoDayHelper
  # Renders a regular link if logged in
  # Otherwise renders a link that redirects to login first
  def link_to_login(title, href, options = {})
    if user_signed_in? && current_user.twitter_authentication.present?
      link_to title, href, options
    else
      options.delete(:onclick) if options[:onclick].present?
      link_to title, capture_and_login_path(:redirect_to => request.fullpath), options
    end
  end
end
