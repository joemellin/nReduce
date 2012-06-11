Nreduce::Application.routes.draw do
  devise_for :users, :controllers => {:registrations => 'registrations'}

  resources :authentications, :users, :checkins

  resources :comments do
    get 'cancel_edit', :on => :member
  end
  
  resources :relationships, :only => [:create, :index] do
    member do
      post 'approve'
      post 'reject'
    end
  end

    # Searching other startups, seeing checkins - plural resource
  resources :startups, :only => [:show] do
    collection do
      get 'search'
      post 'search'
    end
    resources :checkins do
      get 'latest' => "checkins#show", :checkin_id => 'latest', :on => :collection
    end
  end

    # Your startup - singular resource
  resource :startup do
    member do
      get 'onboard'
      post 'onboard_next'
      get 'dashboard'
    end
  end
  
  get "/users/chat" => "users#chat"

  # for omniauth authentications with other providers
  match '/auth/:provider/callback' => 'authentications#create'
  match '/auth/failure' => 'authentications#failure'

  # Easy routes for auth/account stuff
  as :user do
    get '/sign_in' => "devise/sessions#new"
    get '/sign_up' => "registrations#new"
    get '/logout' => "devise/sessions#destroy"
  end

  get "/contact_joe" => "pages#contact_joe"
  

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

  root :to => 'relationships#index'
end
