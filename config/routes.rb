Rails.application.routes.draw do
  ## OAUTH ##
  devise_scope :user do
    get "omniauth/franceconnect/callback" => "omniauth_callbacks#franceconnect"
  end

  devise_for :super_admins # necessary for helpers like super_admin_signed_in?
  devise_scope :super_admin do
    get "omniauth/github/callback" => "omniauth_callbacks#github"
  end

  ## ADMIN ##
  get "connexion_super_admins", to: "welcome#super_admin"

  delete "super_admins/sign_out" => "super_admins/sessions#destroy"

  namespace :super_admins do
    resources :agents do
      get "sign_in_as", on: :member
      post :invite, on: :member
    end
    resources :super_admins
    resources :organisations
    resources :services
    resources :motifs
    resources :users do
      get "sign_in_as", on: :member
    end
    resources :motif_libelles
    resources :webhook_endpoints
    resources :mailer_previews, only: %i[index show]
    root to: "agents#index"

    authenticate :super_admin do
      match "/delayed_job" => DelayedJobWeb, anchor: false, via: %i[get post]
    end
  end
  get "super_admin", to: redirect("super_admins", status: 301)

  devise_scope :user do
    get "users/pending_registration" => "users/registrations#pending"
    get "invitation", to: "users/invitations#new", as: "invitations_landing"
    post "invitation", to: "users/invitations#redirect", as: "invitations_landing_redirection"
  end

  ## APP ##
  devise_for :users,
             controllers: { registrations: "users/registrations", sessions: "users/sessions", passwords: "users/passwords", confirmations: "users/confirmations", invitations: "users/invitations" }

  namespace :users do
    resource :rdv_wizard_step, only: %i[new create]
    resources :rdvs, only: %i[index create] do
      put :cancel
    end
    resources :creneaux, only: %i[index edit update], param: :rdv_id
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
      resources :absences, only: %i[index create]
      resources :users, only: %i[create show] do
        get :invite, on: :member
      end
      resources :user_profiles, only: [:create]
    end
  end

  resources :organisations, only: %i[new create]

  authenticate :agent do
    namespace "admin" do
      resources :territories, only: [:update] do
        scope module: "territories" do
          resources :agent_territorial_roles, only: %i[index new create destroy]
          resources :zone_imports, only: %i[new create]
          resources :zones, only: [:index] # exports only
          resources :sectors do
            resources :zones
            resources :sector_attributions, only: %i[new create destroy], as: :attributions
            delete "/zones" => "zones#destroy_multiple"
          end
          resource :setup_checklist, only: [:show]
          get "sectorisation_test" => "sectorisation_tests#search"
        end
      end

      # Routes pour les ressources du calendrier.
      # TODO trouver un meilleur nom pour éviter la nécessité de ce commentaire :)
      resources :agents, only: [], module: :agents do
        resources :plage_ouvertures, only: [:index]
        resources :rdvs, only: [:index]
        resources :absences, only: [:index]
      end

      resources :organisations do
        resources :plage_ouvertures, except: %i[index new]
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
        resources :absences, except: %i[index show new]
        resources :agent_roles, only: %i[edit update]
        resources :agent_agendas, only: [:show]
        resources :agents, only: %i[index destroy] do
          resources :absences, only: %i[index new]
          resources :plage_ouvertures, only: %i[index new]
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
        resource :merge_users, only: %i[new create]
        resource :rdv_wizard_step, only: [:new] do
          get :create
        end
        devise_for :agents, controllers: { invitations: "admin/invitations_devise" }, only: :invitations
        get "support", to: "static_pages#support"
        resources :support_tickets, only: [:create]
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
  resources :lieux, only: %i[index show]
  resources :motif_libelles, only: :index
  get "health_checks/rdv_events_stats", to: "health_checks#rdv_events_stats"
  get "health_checks/raise_on_purpose", to: "health_checks#raise_on_purpose"
  get "health_checks/enqueue_failing_job", to: "health_checks#enqueue_failing_job"
  root "welcome#index"
  resources :support_tickets, only: [:create]

  # rubocop:disable Style/StringLiterals, Style/FormatStringToken
  # temporary route after admin namespace introduction
  get "/organisations/*rest", to: redirect('admin/organisations/%{rest}')
  # old agenda rule was bookmarked by some agents
  get "admin/organisations/:organisation_id/agents/:agent_id", to: redirect("/admin/organisations/%{organisation_id}/agent_agendas/%{agent_id}")
  # rubocop:enable Style/StringLiterals, Style/FormatStringToken
end
