Nreduce::Application.routes.draw do
  # Main Admin
  mount RailsAdmin::Engine => '/admin', :as => 'rails_admin'
  # Resque Admin
  require 'resque/server'
  mount Resque::Server.new, :at => "/resque"

  devise_for :users, :controllers => {:registrations => 'registrations'}

  resources :authentications, :checkins

  resources :notifications

  resources :meetings, :only => [:index, :show] do
    post 'message_attendees', :on => :member
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

  resources :users do
    collection do
      get 'chat'
      post 'reset_hipchat_account'
    end
  end

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
  resources :startups, :only => [:show, :index] do
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

  match '/mentors/new' => "pages#mentor"
  match '/investors/new' => "pages#investor"


  root :to => 'relationships#index'
end
