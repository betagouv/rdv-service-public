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
    resources :specialites
    resources :motifs
    resources :users
    resources :rdvs
    resources :plage_ouvertures
    root to: "pros#index"

    authenticate :super_admin do
      match "/delayed_job" => DelayedJobWeb, :anchor => false, :via => [:get, :post]
    end
  end

  ## APP ##
  devise_for :pros, controllers: { registrations: 'pros/registrations', invitations: 'pros/invitations' }
  resources :pros, only: [:show, :destroy] do
    post :reinvite, on: :member
  end
  namespace :pros do
    resources :full_subscriptions, only: [:new, :create]
    resources :permissions, only: [:edit, :update]
  end

  authenticated :pro do
    root to: 'agendas#index', as: :authenticated_root
    get "events", to: "agendas#events"
    get "background-events", to: "agendas#background_events"
    resources :organisations, except: :destroy do
      resources :lieux, except: :index
      resources :pros
      resources :users, shallow: true
      resources :motifs, shallow: true
      resources :plage_ouvertures, except: :show, shallow: true

      # Rdv
      resources :rdvs, except: [:index, :create, :new], shallow: true do
        patch :status, on: :member
      end
    end
    resources :first_steps, only: [:new, :create], module: "rdvs"
    resources :second_steps, only: [:new, :create], module: "rdvs"
    resources :third_steps, only: [:new, :create], module: "rdvs"
  end

  { disclaimer: 'mentions_legales', terms: 'cgv' }.each do |k, v|
    get v => "static_pages##{k}"
  end

  get 'accueil_mds' => "welcome#welcome_pro"
  root 'welcome#index'
end
