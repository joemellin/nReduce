Nreduce::Application.routes.draw do
  # Admin constraint
  admin_constraint = lambda do |request|
    request.env['warden'].authenticate? and request.env['warden'].user.admin?
  end

  namespace 'admin' do
    resources :mentors, :only => [:index, :show, :update]
    resources :users, :only => [:show, :index] do
      member do
        get 'sign_in_as'
        post 'approve'
      end
    end
    # Resque Admin
    constraints admin_constraint do
      require 'resque/server'
      mount Resque::Server.new, :at => "/resque"
    end
    # Main Admin - has logic built-in to restrict to admins
    mount RailsAdmin::Engine => '/db', :as => 'rails_admin'
  end

  devise_for :users, :controllers => {:registrations => 'registrations', :sessions => 'sessions'}

  resources :authentications, :checkins, :notifications, :rsvps

  resources :nudges, :only => [:create, :show]

  resources :investors do
    collection do
      get 'show_startup'
    end
  end

  resources :videos do
    collection do
      get 'screencast'
      get 'record'
    end
  end

  resources :meetings, :only => [:index, :show, :edit, :update] do
    post 'message_attendees', :on => :member
    resources :meeting_messages, :only => [:index, :new, :create, :edit]
  end

  resources :awesomes, :only => [:create, :destroy]

  # for omniauth authentications with other providers
  match '/auth/:provider/callback' => 'authentications#create'
  match '/auth/failure' => 'authentications#failure'

  # Easy routes for auth/account stuff
  as :user do
    get '/sign_in' => "devise/sessions#new"
    get '/login' => "devise/sessions#new"
    get '/sign_up' => "registrations#new"
    match '/logout' => "devise/sessions#destroy"
  end

  get "/contact_joe" => "pages#contact_joe"

  get "/home" => "pages#home", :as => "home"
  get "/nstar" => "pages#nstar", :as => "nstar"
  get "/faq" => "pages#faq", :as => "faq"
  get "/team" => "pages#team", :as => "team"
  get "/newmodel" => "pages#newmodel", :as => "newmodel"

  resources :mentors, :only => [:index] do
    collection do
      post 'change_status'
      match 'search'
    end
  end

  resources :users do
    collection do
      get 'chat'
      post 'reset_hipchat_account'
    end
    member do
      match 'account_type'
      match 'complete_account'
      get 'spectator'
      post 'account_type'
      match 'welcome'
      get 'change_password'
    end
    resources :notifications
  end

  match '/users/:id/onboard/:step' => "users#onboard"

  resources :comments do
    member do
      get 'reply_to'
      get 'cancel_edit'
    end
  end

  get '/tags/:context(/:term)' => "tags#search"
  
  resources :relationships, :only => [:create, :index] do
    collection do
      get 'add_teams'
    end
    member do
      post 'approve'
      post 'reject'
    end
  end

    # Searching other startups, seeing checkins - plural resource
  resources :startups, :only => [:show, :index] do
    collection do
      get 'stats'
      match 'invite'
      post 'invite_with_confirm'
    end
    member do
      match 'intro_video'
      match 'before_video'
      get 'mentor_checklist'
      match 'invite_team_members'
    end
    resources :checkins do
      get 'latest' => "checkins#show", :checkin_id => 'latest', :on => :collection
    end
    resources :invites, :only => [:create, :destroy, :show]
    resources :ratings, :only => [:new, :create]
    resources :screenshots, :only => [:create, :update, :destroy]
    resources :instruments, :except => [:index, :destroy]
  end

  # onboarding
  get '/onboard/start(/:type)' => "onboard#start", :as => :onboard_start
  get '/onboard/' => "onboard#current_step", :as => :onboard
  post '/onboard/next' => "onboard#next", :as => :onboard_next

  resources :invites, :only => [:create, :destroy, :show] do
    get 'accept', :on => :member
  end

    # Your startup - singular resource
  resource :startup do
    member do
      post 'remove_team_member'
      get 'investment_profile'
    end
  end

  match '/mentors/new' => "pages#mentor"
  match '/investors/new' => "pages#investor"
  match '/community_guidelines' => "pages#community_guidelines", :as => :community_guidelines


  root :to => 'pages#home'
end
