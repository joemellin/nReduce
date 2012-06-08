Nreduce::Application.routes.draw do
  devise_for :users, :controllers => {:registrations => 'registrations'}

  # for omniauth authentications with other providers
  match '/auth/:provider/callback' => 'authentications#create'
  match '/auth/failure' => 'authentications#failure'

  get "/login" => "auth#login"

  get "/rsvp/edit" => "users#edit_rsvp"
  post "/rsvp/edit" => "users#update_rsvp"
  get "/rsvp/(:user_token)" => "users#rsvp_redirect"

  get '/login' => redirect("/auth/twitter")
  get '/logout' => "authentications#destroy"
  delete '/auth' => "authentications#destroy"

  # vanilla connect (forum SSO)
  match '/vanilla/connect' => 'auth#vanilla_connect'

  # signup stuff
  get "/signup" => redirect("http://nreduce.com/#signup")
  # cors post for signup
  post "/signup" => "signup#create"

  # startup signup form
  get "/startups/new" => "startups#new"
  post "/startups" => "startups#create"

  # startup dashboard
  get "/startup" => "startups#show"
  get "/startup/edit" => "startups#edit"
  post "/startup" => "startups#update"

  # investor signup form
  get "/investors/new" => "investors#new"
  post "/investors" => "investors#create"

  # investor edit
  get "/investor/edit" => "investors#edit"
  post "/investor" => "investors#update"

  # mentor signup form
  get "/mentors/new" => "mentors#new"
  post "/mentors" => "mentors#create"

  # mentor edit
  get "/mentor/edit" => "mentors#edit"
  post "/mentor" => "mentors#update"

  # confirm user
  get "/confirm/:user_token" => "users#confirm"
  get "/thanks/mentor" => "pages#thanks_mentor"
  get "/thanks/startup" => "pages#thanks_startup"
  get "/thanks/investor" => "pages#thanks_investor"
  get "/thanks/spectator" => "pages#thanks_spectator"

  # TESTING get "/testmail" => "pages#startup"

  match "/admin" => redirect("/admin/startups")
  scope :module => "Admin" do
    get "/admin/startups" => "admin_startups#index"
    get "/admin/startups/:id" => "admin_startups#show"
    post "/admin/startups/:id/approve" => "admin_startups#approve_startup"
    post "/admin/startups/:id/deny" => "admin_startups#deny_startup"

    match "/admin/authentications" => "admin_authentications#index"
    post "/admin/authentications/:id/set_partner" => "admin_authentications#set_partner"

    get "/admin/locations" => "admin_locations#index"
    get "/admin/locations/new" => "admin_locations#new"
    post "/admin/locations" => "admin_locations#create"

    get "/admin/locations/:id/edit" => "admin_locations#edit"
    post "/admin/locations/:id/edit" => "admin_locations#update"
    delete "/admin/locations/:id" => "admin_locations#destroy"

    get "/admin/rsvps" => "admin_rsvps#index"

    match "/admin/signups" => "admin_signups#index"
  end

  # ui tools
  scope :module => "Test" do
    match "/test/alert" => "tools#test_alert"
    match "/test/notice" => "tools#test_notice"
    match "/comps/:action" => "comps"
    match "/comps" => "comps#index"
    match "/bootstrap" => redirect("/ui")
    match "/test/bootstrap" => redirect("/ui")
    match "/ui/:action" => "bootstrap"
    match "/ui" => "bootstrap#index"
  end

  # You can have the root of your site routed with "root"
  # just remember to delete public/index.html.
  root :to => 'users#show'
end
