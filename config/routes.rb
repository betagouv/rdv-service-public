# frozen_string_literal: true

Rails.application.routes.draw do
  mount Rswag::Ui::Engine => '/api-docs'
  mount Rswag::Api::Engine => '/api-docs'
  ## OAUTH ##
  devise_scope :user do
    get "omniauth/franceconnect/callback" => "omniauth_callbacks#franceconnect"
  end

  get "inclusion_connect/auth" => "inclusion_connect#auth"
  get "inclusion_connect/callback" => "inclusion_connect#callback"

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
      resources :migrations, only: %i[new create]
    end
    resources :super_admins
    resources :organisations
    resources :services
    resources :motifs
    resources :lieux
    resources :territories
    resources :users do
      get "sign_in_as", on: :member
    end
    root to: "agents#index"

    authenticate :super_admin do
      mount GoodJob::Engine => "good_job"
    end
  end
  get "super_admin", to: redirect("super_admins", status: 301)

  devise_scope :user do
    get "users/pending_registration" => "users/registrations#pending"
    get "invitation", to: "users/invitations#invitation", as: "invitations_landing"
  end

  ## APP ##
  devise_for :users,
             controllers: { registrations: "users/registrations", sessions: "users/sessions", passwords: "users/passwords", confirmations: "users/confirmations", invitations: "users/invitations" }

  namespace :users do
    resource :rdv_wizard_step, only: %i[new create]
    resources :rdvs, only: %i[index create show edit update] do
      resources :participations, only: %i[index create]
      put "participations/cancel", to: "participations#cancel"
      member do
        get :creneaux
        put :cancel
      end
    end
    resource :user_name_initials_verification, only: %i[new create], controller: "user_name_initials_verification"
    post "file_attente", to: "file_attentes#create_or_delete"
  end
  resources :stats, only: :index
  get "stats/rdvs", to: "stats#rdvs", as: "rdvs_stats"
  get "stats/active_agents", to: "stats#active_agents", as: "active_agents_stats"
  get "stats/receipts", to: "stats#receipts", as: "receipts_stats"
  get "stats/notifications", to: "stats#notifications_index", as: "notifications_index_stats"

  authenticate :user do
    get "/users/informations", to: "users/users#edit"
    patch "users/informations", to: "users/users#update"
    resources :relatives, except: %i[index show], controller: "users/relatives"
  end
  authenticated :user do
    get "/users/rdvs", to: "users/rdvs#index"
  end

  devise_for :agents, controllers: {
    invitations: "admin/territories/invitations_devise", # only using the accept route here
    sessions: "agents/sessions",
    passwords: "agents/passwords",
  }

  devise_scope :agent do
    get "agents/edit" => "agents/registrations#edit", as: "edit_agent_registration"
    put "agents" => "agents/registrations#update", as: "agent_registration"
    delete "agents" => "agents/registrations#destroy", as: "delete_agent_registration"
    namespace :agents do
      resource :preferences, only: %i[show update] do
        post :disable_cnfs_online_booking_banner
      end
      resource :calendar_sync, only: %i[show], controller: :calendar_sync do
        resource :webcal_sync, only: %i[show update], controller: :webcal_sync
        resource :outlook_sync, only: %i[show destroy], controller: :outlook_sync
      end
    end
    get "omniauth/microsoft_graph/callback" => "omniauth_callbacks#microsoft_graph"
  end

  get "/calendrier/:id", controller: :ics_calendar, action: :show, as: :ics_calendar

  resources :organisations, only: %i[new create]

  authenticate :agent do
    namespace "admin" do
      resources :territories, only: %i[edit update show] do
        scope module: "territories" do
          resources :agent_roles, only: %i[edit update create destroy]
          resources :agent_territorial_access_rights, only: %i[update]
          resources :webhook_endpoints, except: %i[show]
          resources :agents, only: %i[index update edit] do
            member do
              put :territory_admin
            end
          end
          resources :teams
          resource :user_fields, only: %i[edit update]
          resource :rdv_fields, only: %i[edit update]
          resource :motif_fields, only: %i[edit update]
          resource :motif_categories, only: %i[update]
          resource :sms_configuration, only: %i[show edit update]
          resources :zone_imports, only: %i[new create]
          resources :zones, only: [:index] # exports only
          resource :sectorization, only: [:show]
          resources :sectors do
            resources :zones
            resources :sector_attributions, only: %i[new create destroy], as: :attributions
            delete "/zones" => "zones#destroy_multiple"
          end
          get "sectorisation_test" => "sectorisation_tests#search"

          devise_for :agents, controllers: { invitations: "admin/territories/invitations_devise" }, only: :invitations
        end
      end

      # Routes pour les ressources du calendrier.
      # TODO trouver un meilleur nom pour éviter la nécessité de ce commentaire :)
      resources :agents, only: %i[], module: :agents do
        resources :plage_ouvertures, only: [:index]
        resources :rdvs, only: [:index]
        resources :absences, only: [:index]
      end

      resources :organisations do
        resources :plage_ouvertures, except: %i[index new]
        resources :agent_searches, only: :index, module: "creneaux"
        resources :slots, only: :index
        resources :lieux, except: :show
        resources :motifs
        resources :rdvs_collectifs, only: %i[index new create edit update] do
          collection do
            resources :motifs, only: [:index], as: :rdvs_collectif_motifs, controller: "rdvs_collectifs/motifs"
          end
        end
        resources :rdvs, except: [:new] do
          resources :participations, only: %i[update destroy]
          resource :user_in_waiting_room, only: [:create]
          member do
            post :send_reminder_manually
          end
          collection do
            post :rdvs_users_export
            post :export
          end
        end
        scope module: "organisations" do
          resource :setup_checklist, only: [:show]
          resource :online_booking, only: [:show]
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
          resources :referent_assignations, only: %i[index create destroy]
        end
        resources :absences, except: %i[index show new]
        resources :agent_agendas, only: %i[show] do
          put :toggle_displays, on: :member
        end
        resources :agent_roles, only: %i[edit update]
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
      end
    end
  end
  authenticated :agent do
    root to: "admin/organisations#index", as: :authenticated_agent_root, defaults: { follow_unique: "1" }
  end

  scope path: "prescripteur", as: "prescripteur", controller: "prescripteur_rdv_wizard" do
    get "start"
    get "new_prescripteur"
    post "save_prescripteur"
    get "new_beneficiaire"
    post "create_rdv"
    get "confirmation"
  end

  %w[contact mds accessibility mentions_legales cgu politique_de_confidentialite domaines health_check].each do |page_name|
    get page_name => "static_pages##{page_name}"
  end
  get "/.well-known/microsoft-identity-association" => "static_pages#microsoft_domain_verification", format: :json

  get "/budget", to: redirect("https://pad.incubateur.net/3hxhbOuaSyapxRUg_PnA5g#ANCT-L%E2%80%99Incubateur-des-Territoires", status: 302)

  ## Shorten urls for SMS
  get "r", to: redirect("users/rdvs", status: 301), as: "rdvs_short"

  # We keep this deprecated route because some users have received sms or emails with this kind of link
  get "r/:id", to: (redirect do |path_params, req|
    query_params = format_redirect_params(req.params)
    "users/rdvs/#{path_params[:id]}#{query_params}"
  end), as: "rdv_short_deprecated"

  # tkn est obligatoire pour s'assurer qu'il est possible de se connecter
  get "r/:id/:tkn", to: (redirect do |path_params, req|
    query_params = format_redirect_params(req.params)
    "users/rdvs/#{path_params[:id]}#{query_params}"
  end), as: "rdv_short"

  # TODO: remplacer `prendre_rdv` par le root_path
  get "prdv", to: (redirect do |_path_params, req|
    query_params = format_redirect_params(req.params)
    "prendre_rdv#{query_params}"
  end), as: "prendre_rdv_short"

  get "r/:id/cr", to: (redirect do |path_params, req|
    query_params = format_redirect_params(req.params)
    "users/rdvs/#{path_params[:id]}/creneaux#{query_params}"
  end), as: "creneaux_users_rdv_short"

  def format_redirect_params(params)
    # we rename the short parameter tkn
    params[:invitation_token] ||= params.delete(:tkn) if params[:tkn]
    params.delete(:id) # id is passed through path_params
    params.values.any? ? "?#{params.to_query}" : ''
  end

  # short public link
  get "org/:organisation_id(/:org_slug)" => "search#public_link_with_internal_organisation_id", as: :public_link_to_org
  get "org/ext/:territory/:organisation_external_id(/:org_slug)" => "search#public_link_with_external_organisation_id", as: :public_link_to_external_org

  # resin public link
  get "resin/:external_organisation_ids" => "search#resin"

  get "prendre_rdv_prescripteur" => "search#prescripteur", as: :prendre_rdv_prescripteur

  ##

  get "accueil_mds", to: redirect("presentation_agent", status: 307)
  get "presentation_agent" => "static_pages#presentation_for_agents"

  resources :lieux, only: %i[index show]
  root "search#search_rdv"

  # TODO: remplacer `prendre_rdv` par le root_path
  get "/prendre_rdv", to: "search#search_rdv"

  # rubocop:disable Style/FormatStringToken
  # temporary route after admin namespace introduction
  get "/organisations/*rest", to: redirect('admin/organisations/%{rest}')
  # old agenda rule was bookmarked by some agents
  get "admin/organisations/:organisation_id/agents/:agent_id", to: redirect("/admin/organisations/%{organisation_id}/agent_agendas/%{agent_id}")
  # rubocop:enable Style/FormatStringToken

  post "/inbound_emails/sendinblue", controller: :inbound_emails, action: :sendinblue

  if Rails.env.development?
    namespace :lapin do
      resources :sms_preview, only: %i[index] do
        get ":action_name", to: "sms_preview#preview", as: "preview"
      end
    end

    # LetterOpener
    mount LetterOpenerWeb::Engine, at: "/letter_opener"
  end

  ## APIs
  draw :api
end
