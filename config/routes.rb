Rails.application.routes.draw do
  ## ADMIN ##
  devise_for :super_admins, controllers: { omniauth_callbacks: 'super_admins/omniauth_callbacks' }

  delete 'admin/sign_out' => 'super_admins/sessions#destroy'

  namespace :admin do
    resources :pros do
      get 'sign_in_as', on: :member
    end
    resources :super_admins
    resources :organisations
    resources :lieux
    resources :services
    resources :motifs
    resources :users
    resources :rdvs
    resources :plage_ouvertures
    root to: "pros#index"

    authenticate :super_admin do
      match "/delayed_job" => DelayedJobWeb, anchor: false, via: [:get, :post]
    end
  end

  ## APP ##
  devise_for :users, controllers: { registrations: 'users/registrations', invitations: 'common/invitations' }
  namespace :users do
    resources :rdvs, only: [:index]
  end
  authenticated :user do
    root to: 'users/rdvs#index', as: :authenticated_user_root
  end

  devise_for :pros, controllers: { registrations: 'pros/registrations', invitations: 'common/invitations' }
  resources :pros, only: [:show, :destroy] do
    post :reinvite, on: :member
  end
  namespace :pros do
    resources :full_subscriptions, only: [:new, :create]
    resources :permissions, only: [:edit, :update]
  end
  authenticated :pro do
    root to: 'agendas#index', as: :authenticated_pro_root
    get "events", to: "agendas#events"
    get "background-events", to: "agendas#background_events"
    resources :organisations, except: :destroy do
      resources :lieux, except: :index
      resources :pros
      resources :users, except: :show, shallow: true, controller: 'organisations/users'
      resources :motifs, shallow: true
      resources :plage_ouvertures, except: :show, shallow: true

      # Rdv
      resources :rdvs, except: [:index, :create, :new], shallow: true, controller: 'pros/rdvs' do
        patch :status, on: :member
      end
    end
    [:first_steps, :second_steps, :third_steps].each do |step|
      resources step, only: [:new, :create], module: "pros/rdvs"
    end
    resources :absences, except: :show
  end

  { disclaimer: 'mentions_legales', terms: 'cgv' }.each do |k, v|
    get v => "static_pages##{k}"
  end

  get 'accueil_mds' => "welcome#welcome_pro"
  post '/' => "welcome#search"
  get 'departement/:departement', to: "welcome#welcome_departement", as: "welcome_departement"
  post 'departement/:departement' => "welcome#search_departement"
  get 'departement/:departement/:motif', to: "welcome#welcome_motif", as: "welcome_motif"
  root 'welcome#index'
end
