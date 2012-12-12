Nreduce::Application.routes.draw do
  # Admin constraint
  admin_constraint = lambda do |request|
    request.env['warden'].authenticate? and request.env['warden'].user.admin?
  end

  namespace 'admin' do
    resources :metrics, :only => [:index]
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
      require 'resque_scheduler'
      require 'resque_scheduler/server'
      mount Resque::Server.new, :at => "/resque"
    end
    # Main Admin - has logic built-in to restrict to admins
    mount RailsAdmin::Engine => '/db', :as => 'rails_admin'
  end

  devise_for :users, :controllers => {:registrations => 'registrations', :sessions => 'sessions'}

  resources :authentications, :rsvps

  resources :conversations, :path => "messages" do
    collection do
      post 'search_startups'
      post 'mark_all_as_seen'
    end
    member do
      post 'add_message'
    end
  end

  resources :requests do
    member do
      post 'cancel'
    end
    resources :responses do
      member do
        post 'complete'
        post 'accept'
        post 'cancel'
        post 'reject'
      end
    end
  end
  get '/responses/:id/thank_you' => 'responses#thank_you', :as => 'thank_you_response'

  resources :payments do
    member do
      post 'cancel'
    end
  end

  resources :notifications, :only => [:index] do
    collection do
      post 'mark_all_as_read'
    end
  end

  resources :checkins do
    collection do
      match 'first'
    end
  end

  resources :nudges, :only => [:create, :show] do
    collection do
      post 'nudge_all_inactive'
    end
  end

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

  resources :calls do
    collection do
      post 'receive'
      post 'other_party_unavailable'
      post 'connected'
      post 'completed'
      post 'failed'
      get 'dial'
    end
  end

  match '/sms/receive' => 'sms#receive'

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
  get "/mentorsphone" => "pages#mentorsphone", :as => "mentorsphone"
  get "/home" => "pages#home", :as => "home"
  get "/nstar" => "pages#nstar", :as => "nstar"
  get "/faq" => "pages#faq", :as => "faq"
  get "/heartstartups" => "pages#heartstartups", :as => "heartstartups"
  get "/team" => "pages#team", :as => "team"
  get "/newmodel" => "pages#newmodel", :as => "newmodel"
  get "/local" => "pages#local", :as => "local"
  get "/helpproto" => "pages#helpproto", :as => "helpproto"
  get "/tos" => "pages#tos", :as => "tos"
  get "/privacy" => "pages#privacy", :as => "privacy"
  get "/testemail" => "pages#testemail", :as => "testemail"
  get "/metrics" => "pages#metrics", :as => "metrics"
  get "/success_modal" => "pages#success_modal", :as => "success_modal"
  get "/twitter_url" => "pages#twitter_url", :as => "twitter_url"
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
      get 'current_class'
      get 'wait_for_next_class'
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
      post 'skip_team'
      get 'requests'
      post 'mark_all_as_seen'
    end
    member do
      post 'approve'
      post 'reject'
    end
  end

    # Searching other startups, seeing checkins - plural resource
  resources :startups, :only => [:show, :index] do
    collection do
      get 'wait_for_next_class'
      get 'current_class'
      get 'stats'
      match 'invite'
      post 'invite_with_confirm'
      match 'search'
    end
    member do
      match 'intro_video'
      match 'before_video'
      get 'mentor_checklist'
      match 'invite_team_members'
      get 'mini_profile'
      get 'investment_profile'
    end
    resources :checkins do
      get 'latest' => "checkins#show", :checkin_id => 'latest', :on => :collection
    end
    resources :invites, :only => [:create, :destroy, :show]
    resources :ratings, :only => [:index, :new, :create]
    resources :screenshots, :only => [:create, :update, :destroy]
    resources :instruments, :except => [:index, :destroy]
    resources :questions, :except => [:update, :destroy] do
      member do
        post 'support'
        post 'answer'
      end
    end
  end

  resources :ratings, :only => [:index, :new, :create]

  resources :weekly_classes, :only => [:show] do
    member do 
      get 'update_state'
      post 'graduate'
      get 'join'
    end
  end

  # onboarding
  get '/onboard/start(/:type)' => "onboard#start", :as => :onboard_start
  get '/onboard/' => "onboard#current_step", :as => :onboard
  post '/onboard/next' => "onboard#next", :as => :onboard_next
  get '/onboard/go_to/:step' => "onboard#go_to", :as => :onboard_go_to
  get '/onboard/:id' => "onboard#show"

  resources :invites, :only => [:create, :destroy, :show] do
    get 'accept', :on => :member
  end

    # Your startup - singular resource
  resource :startup do
    member do
      post 'remove_team_member'
      get 'investment_profile'
      post 'add_invite_field'
      post 'invite_ajax'
    end
  end

  resources :posts, :only => [:index, :show] do
    post 'repost', :on => :member
  end

  match '/work_room' => 'relationships#index', :as => :work_room
  match '/board_room' => 'ratings#index', :as => :board_room
  match '/join' => 'application#join', :as => :join
  match 'startups/edit' => "startups#edit", :as => :startups_edit
  match '/mentor' => "pages#mentor", :as => :public_mentors
  match '/investor' => "pages#investor", :as => :public_investors
  match '/press' => "pages#press", :as => :public_press
  match '/tutorial' => "pages#tutorial", :as => :tutorial
  match '/why_join' => "pages#why_join", :as => :why_join
  match '/coworking_location' => 'pages#coworking_location', :as => :coworking_location
  match '/community_guidelines' => "pages#community_guidelines", :as => :community_guidelines

  # Url redirection
  match '/ciao/:url' => "application#ciao", :as => :ciao

  match '/capture_and_login' => 'application#capture_and_login', :as => :capture_and_login

  match '/nstars/:id/:startup_id' => 'demo_day#show_startup', :as => :show_startup_demo_day

  resources :demo_day, :only => [:index, :show], :path => 'nstars' do
    post 'attend', :on => :member
  end

  # Match old routes for demo day
  match '/d' => 'demo_day#index'
  match '/d/:startup_index' => 'demo_day#show_startup', :old_id => true, :id => 1

  root :to => 'pages#home'
end
