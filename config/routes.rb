Rails.application.routes.draw do
  ## ADMIN ##
  devise_for :super_admins, controllers: { omniauth_callbacks: 'super_admins/omniauth_callbacks' }

  delete 'admin/sign_out' => 'super_admins/sessions#destroy'

  namespace :admin do
    resources :pros do
      get 'sign_in_as', on: :member
      post :invite, on: :member
    end
    resources :super_admins
    resources :organisations
    resources :lieux
    resources :services
    resources :motifs
    resources :users
    resources :rdvs
    resources :plage_ouvertures
    resources :absences
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
  as :pro do
    get 'pros/edit' => 'pros/registrations#edit', as: 'edit_pro_registration'
    put 'pros' => 'pros/registrations#update', :as => 'pro_registration'
  end
  namespace :pros do
    resources :full_subscriptions, only: [:new, :create]
    resources :permissions, only: [:edit, :update]
  end
  authenticated :pro do
    root to: 'agendas#index', as: :authenticated_pro_root
    get "events", to: "agendas#events"
    get "background-events", to: "agendas#background_events"
    resources :lieux, except: :show
    resources :pros, only: [:index, :destroy] do
      post :reinvite, on: :member
    end
    resources :motifs, except: :show
    resources :plage_ouvertures, except: :show
    resources :organisations do
      resources :users, except: :show, shallow: true, controller: 'organisations/users'

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
  resources :creneaux, only: [:index]
  root 'welcome#index'
end
