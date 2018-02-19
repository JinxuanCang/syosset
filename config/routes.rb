Rails.application.routes.draw do
  # Main pages
  root 'welcome#index'
  get 'landing' => 'welcome#landing' # browser homepage on school devices
  get 'about' => 'welcome#about'
  get 'status' => 'welcome#status' # to check that app is alive upon deploy

  get 'z/index.html', to: redirect("/") # legacy endpoint -> still set on school devices (Syosset/syosset#83)

  # Authentication
  get '/login' => 'sessions#new'
  delete '/logout' => 'sessions#destroy'
  match '/auth/:provider/callback' => 'sessions#create', via: [:get, :post]
  get '/auth/failure' => 'sessions#failure'

  # Users
  resources :users, only: [:index, :new, :show, :edit, :update] do
    get '/admin/edit' => 'users#admin_edit'
    patch '/admin' => 'users#admin_update'
    post :populate, on: :collection # create multiple users and assign to collaborator groups

    get :autocomplete, on: :collection
    resources :periods, on: :member, except: [:show]
  end

  # User content
  resources :activities

  resources :departments, shallow: true do
    member do
      post :subscribe
      post :unsubscribe
    end
    resources :courses do
      member do
        post :subscribe
        post :unsubscribe
      end
    end
  end

  resources :announcements
  resources :links, except: [:show]

  # Alerts
  resources :alerts do
    collection do
      post "read_all"
    end
  end

  # Escalation Requests
  resources :escalation_requests, path: 'escalations' do
    post "approve", action: :approve, as: :approve
    post "deny", action: :deny, as: :deny
  end

  # Collaborator Management
  resources :collaborator_groups, only: [:edit, :update] do
    post "add_collaborator", action: :add_collaborator, as: :add_collaborator
    post "remove_collaborator", action: :remove_collaborator, as: :remove_collaborator
  end

  # Admin Panel
  get 'admin' => 'admin#index'
  post 'admin/renew' => 'admin#renew'
  post 'admin/resign' => 'admin#resign'

  # Day Color and Closures
  resource :day, only: [:show, :edit, :update] do
    post 'fetch'
  end

  resources :closures

  # Promotions
  resources :promotions

  # Badge Management
  resources :badges, except: [:show]

  # Integration Management
  resources :integrations do
    post :clear_failures, on: :member
  end

  # Message Threads
  get '/threads/create' => 'message_threads#create'
  get '/threads/:id/messages' => 'message_threads#read_messages'
  post '/threads/:id/messages' => 'message_threads#send_message'

  # Auditing
  resources :history_trackers, only: [:index, :show]

  # Autocomplete AJAX
  get 'autocomplete', to: 'application#autocomplete'

  # Sortable AJAX
  post "/rankables/sort" => "rankables#sort", :as => :sort_rankable

  # Attachments
  post "/attachments" => "attachments#create"

  # Utilities
  mount Peek::Railtie => '/peek'
end
