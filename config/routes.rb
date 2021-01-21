Rails.application.routes.draw do
  ## ADMIN ##
  devise_for :super_admins, controllers: { omniauth_callbacks: "super_admins/omniauth_callbacks" }

  get "connexion_super_admins", to: "welcome#super_admin"

  delete "super_admins/sign_out" => "super_admins/sessions#destroy"

  namespace :super_admins do
    resources :agents do
      get "sign_in_as", on: :member
      post :invite, on: :member
    end
    resources :super_admins
    resources :organisations
    resources :lieux
    resources :services
    resources :motifs
    resources :users do
      get "sign_in_as", on: :member
    end
    resources :rdvs
    resources :plage_ouvertures
    resources :absences
    resources :motif_libelles
    resources :webhook_endpoints
    resources :mailer_previews, only: [:index, :show]
    root to: "agents#index"

    authenticate :super_admin do
      match "/delayed_job" => DelayedJobWeb, anchor: false, via: [:get, :post]
    end
  end
  get "super_admin", to: redirect("super_admins", status: 301)

  devise_scope :user do
    get "users/pending_registration" => "users/registrations#pending"
  end

  ## APP ##
  devise_for :users, controllers: { registrations: "users/registrations", sessions: "users/sessions", passwords: "users/passwords", confirmations: "users/confirmations", invitations: "users/invitations", }

  namespace :users do
    resource :rdv_wizard_step, only: [:new, :create]
    resources :rdvs, only: [:index, :create] do
      put :cancel
    end
    resources :creneaux, only: [:index, :edit, :update], param: :rdv_id
    post "file_attente", to: "file_attentes#create_or_delete"
  end
  resources :stats, only: :index
  get "stats/agents", to: "stats#agents", as: "agents_stats"
  get "stats/organisations", to: "stats#organisations", as: "organisations_stats"
  get "stats/rdvs", to: "stats#rdvs", as: "rdvs_stats"
  get "stats/users", to: "stats#users", as: "users_stats"
  get "stats/:departement", to: "stats#index", as: "departement_stats"

  authenticate :user do
    get "/users/informations", to: "users/users#edit"
    patch "users/informations", to: "users/users#update"
    resources :relatives, except: [:index], controller: "users/relatives"
  end
  authenticated :user do
    get "/users/rdvs", to: "users/rdvs#index", as: :authenticated_user_root
  end

  devise_for :agents, controllers: {
    invitations: "admin/invitations_devise", # only using the accept route here
    sessions: "agents/sessions",
    passwords: "agents/passwords"
  }

  as :agent do
    get "agents/edit" => "agents/registrations#edit", as: "edit_agent_registration"
    put "agents" => "agents/registrations#update", as: "agent_registration"
    delete "agents" => "agents/registrations#destroy", as: "delete_agent_registration"
  end

  namespace :api do
    namespace :v1 do
      mount_devise_token_auth_for "AgentWithTokenAuth", at: "auth"
      resources :absences, only: [:index, :create]
    end
  end

  resources :organisations, only: [:new, :create]

  authenticate :agent do
    namespace "admin" do
      resources :departements, only: [] do
        scope module: "departements" do
          resources :zone_imports, only: [:new, :create]
          resources :sectors do
            resources :zones, except: [:index]
            resources :sector_attributions, only: [:new, :create, :destroy], as: :attributions
            delete "/zones" => "zones#destroy_multiple"
          end
          resource :setup_checklist, only: [:show]
          get "sectorisation_test" => "sectorisation_tests#search"
        end
      end

      resources :organisations do
        resources :plage_ouvertures, except: [:index, :new]
        resources :agent_searches, only: :index, module: "creneaux"
        resources :lieux, except: :show
        resources :motifs
        resources :rdvs, except: [:new] do
          resources :versions, only: [:index]
        end
        scope module: "organisations" do
          resource :setup_checklist, only: [:show]
          resources :stats, only: :index do
            collection do
              get :rdvs
              get :users
            end
          end
        end
        resources :users do
          member do
            post :invite
            get :link_to_organisation
          end
          collection do
            get :search
          end
          resource :referents, only: [:update]
        end
        resources :absences, except: [:index, :show, :new]
        resources :agents, only: [:index, :show, :destroy] do
          collection do
            resources :permissions, only: [:edit, :update]
          end
          resources :absences, only: [:index, :new]
          resources :plage_ouvertures, only: [:index, :new]
          resources :stats, only: :index do
            collection do
              get :rdvs
              get :users
            end
          end
        end
        resources :invitations, only: [:index] do
          post :reinvite, on: :member
        end
        resource :merge_users, only: [:new, :create]
        resource :rdv_wizard_step, only: [:new, :create]
        devise_for :agents, controllers: { invitations: "admin/invitations_devise" }, only: :invitations
      end

      resources :jours_feries, only: [:index]
    end
  end
  authenticated :agent do
    root to: "admin/organisations#index", as: :authenticated_agent_root, defaults: { follow_unique: "1" }
  end

  { contact: "contact", mds: "mds" }.each do |k, v|
    get v => "static_pages##{k}"
  end

  get "r", to: redirect("users/rdvs", status: 301), as: "rdvs_shorten"
  get "accueil_mds" => "welcome#welcome_agent"
  post "/" => "welcome#search"
  get "departement/:departement", to: "welcome#welcome_departement", as: "welcome_departement"
  post "departement/:departement" => "welcome#search_departement"
  get "departement/:departement/:service", to: "welcome#welcome_service", as: "welcome_service"
  get "departement/:departement/:service/:motif", to: "welcome#welcome_motif", as: "welcome_motif"
  resources :lieux, only: [:index, :show]
  resources :motif_libelles, only: :index
  get "health_checks/rdv_events_stats", to: "health_checks#rdv_events_stats"
  get "health_checks/raise_on_purpose", to: "health_checks#raise_on_purpose"
  get "health_checks/enqueue_failing_job", to: "health_checks#enqueue_failing_job"
  root "welcome#index"
  resources :support_tickets, only: [:create]

  # temporary route after admin namespace introduction
  # rubocop:disable Style/StringLiterals, Style/FormatStringToken
  get "/organisations/*rest", to: redirect('admin/organisations/%{rest}')
  # rubocop:enable Style/StringLiterals, Style/FormatStringToken
end
