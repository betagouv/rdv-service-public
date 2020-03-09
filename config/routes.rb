Rails.application.routes.draw do
  ## ADMIN ##
  devise_for :super_admins, controllers: { omniauth_callbacks: 'super_admins/omniauth_callbacks' }

  delete 'admin/sign_out' => 'super_admins/sessions#destroy'

  namespace :admin do
    resources :agents do
      get 'sign_in_as', on: :member
      post :invite, on: :member
    end
    resources :super_admins
    resources :organisations
    resources :lieux
    resources :services
    resources :motifs
    resources :users do
      get 'sign_in_as', on: :member
    end
    resources :rdvs
    resources :plage_ouvertures
    resources :absences
    resources :motif_libelles
    root to: "agents#index"

    authenticate :super_admin do
      match "/delayed_job" => DelayedJobWeb, anchor: false, via: [:get, :post]
      mount Flipflop::Engine => "/flipflop", as: "flipflop"
    end
  end

  ## APP ##
  devise_for :users, controllers: { registrations: 'users/registrations', sessions: 'sessions', confirmations: 'users/confirmations' }

  namespace :users do
    resources :rdvs, only: [:index, :new, :create] do
      put :cancel
      get :confirmation
    end
    resources :creneaux, only: [:index, :edit, :update], param: :rdv_id
    post 'file_attente', to: 'file_attentes#create_or_delete'
  end
  resources :stats, only: :index
  get 'stats/rdvs', to: "stats#rdvs", as: "rdvs_stats"
  get 'stats/users', to: "stats#users", as: "users_stats"

  authenticate :user do
    get "/users/informations", to: 'users/users#edit'
    patch "users/informations", to: 'users/users#update'
    resources :children, except: [:index], controller: "users/children"
  end
  authenticated :user do
    get "/users/rdvs", to: 'users/rdvs#index', as: :authenticated_user_root
  end

  devise_for :agents, controllers: { invitations: 'agents/invitations', sessions: 'sessions' }

  as :agent do
    get 'agents/edit' => 'agents/registrations#edit', as: 'edit_agent_registration'
    put 'agents' => 'agents/registrations#update', as: 'agent_registration'
    delete 'agents' => 'agents/registrations#destroy', as: 'delete_agent_registration'
  end

  authenticate :agent do
    scope module: "agents" do
      resources :organisations, except: :destroy do
        resources :lieux, except: :show
        resources :motifs
        resources :plage_ouvertures, except: [:index, :show, :new]
        resources :absences, except: [:index, :show, :new]

        get "agent", to: "agents#show", as: "agent_with_id_in_query"
        resources :agents, only: [:index, :show, :destroy] do
          post :reinvite, on: :member
          collection do
            resources :full_subscriptions, only: [:new, :create]
            resources :permissions, only: [:edit, :update]
          end

          resources :rdvs, only: :index
          resources :absences, only: [:index, :new]
          resources :plage_ouvertures, only: [:index, :new]
        end

        resources :users do
          member do
            post :invite
            get :link_to_organisation
          end
          collection do
            get :search
            post :create_from_modal
          end
          resources :rdvs, only: :index
          resources :children, only: [:create, :new]
        end
        resources :children, except: [:create, :new]

        resources :rdvs, except: [:index, :create, :new] do
          patch :status, on: :member
        end

        resources :agent_searches, only: :index, module: "creneaux" do
          get :by_lieu, on: :collection
        end

        [:first_steps, :second_steps, :third_steps].each do |step|
          resources step, only: [:new, :create], module: "rdvs"
        end
      end
      resources :jours_feries, only: [:index]
    end
  end
  authenticated :agent do
    root to: 'agents/organisations#index', as: :authenticated_agent_root
  end

  { disclaimer: 'mentions_legales', terms: 'cgv', mds: 'mds' }.each do |k, v|
    get v => "static_pages##{k}"
  end

  get 'r', to: redirect('users/rdvs', status: 301), as: "rdvs_shorten"
  get 'accueil_mds' => "welcome#welcome_agent"
  post '/' => "welcome#search"
  get 'departement/:departement', to: "welcome#welcome_departement", as: "welcome_departement"
  post 'departement/:departement' => "welcome#search_departement"
  get 'departement/:departement/:service', to: "welcome#welcome_service", as: "welcome_service"
  get 'departement/:departement/:service/:motif', to: "welcome#welcome_motif", as: "welcome_motif"
  resources :lieux, only: [:index, :show]
  resources :motif_libelles, only: :index
  root 'welcome#index'
end
