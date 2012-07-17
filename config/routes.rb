Nreduce::Application.routes.draw do
  # Admin constraint
  admin_constraint = lambda do |request|
    request.env['warden'].authenticate? and request.env['warden'].user.admin?
  end

  namespace 'admin' do
    resources :mentors, :only => [:index, :show, :update]
    resources :users, :only => :show do
      get 'sign_in_as', :on => :member
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

  resources :authentications, :checkins

  resources :notifications

  resources :nudges, :only => [:create, :show]

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
    member do
      post 'approve'
      post 'reject'
    end
  end

    # Searching other startups, seeing checkins - plural resource
  resources :startups, :only => [:show, :index] do
    collection do
      get 'search'
      post 'search'
      get 'stats'
      match 'invite'
    end
    member do
      match 'before_video'
      get 'mentor_checklist'
      match 'invite_team_members'
    end
    resources :checkins do
      get 'latest' => "checkins#show", :checkin_id => 'latest', :on => :collection
    end
    resources :invites, :only => [:create, :destroy, :show]
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
    end
  end

  match '/mentors/new' => "pages#mentor"
  match '/investors/new' => "pages#investor"
  match '/community_guidelines' => "pages#community_guidelines", :as => :community_guidelines


  root :to => 'relationships#index'
end
