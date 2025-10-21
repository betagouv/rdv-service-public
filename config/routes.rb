Rails.application.routes.draw do
  mount Rswag::Ui::Engine => "/api-docs"
  mount Rswag::Api::Engine => "/api-docs"

  get "agent_connect/auth" => "agent_connect#auth"
  get "agent_connect/callback" => "agent_connect#callback"

  get "franceconnect_v2/auth" => "france_connect_v2#auth"
  get "franceconnect_v2/callback" => "france_connect_v2#callback"
  get "franceconnect_v2/post_logout" => "france_connect_v2#post_logout"
  get "franceconnect_v2/sector_identifier" => "static_pages#france_connect_sector_identifier"

  devise_for :super_admins # necessary for helpers like super_admin_signed_in?
  devise_scope :super_admin do
    get "omniauth/github/callback" => "omniauth_callbacks#github"
  end

  ## OAUTH PROVIDER ##
  use_doorkeeper do
    skip_controllers :applications # Ces routes permettent de configurer les applications OAuth autorisées
    # Par soucis de sécurité, on préfère les fermer, et permettre la configuration de ces applications uniquement par des devs en console.
    # voir scripts/create_oauth_application.rb
  end

  ## ADMIN ##
  get "connexion_super_admins", to: "welcome#super_admin"

  delete "super_admins/sign_out" => "super_admins/sessions#destroy"

  namespace :super_admins do
    resources :agents, except: [:destroy] do
      get "sign_in_as", on: :member
      post :invite, on: :member
      resources :migrations, only: %i[new create]
      post :toggle_feature, on: :member, as: :toggle_feature
    end
    resources :agent_roles, only: %i[show edit update destroy]
    resources :agent_territorial_access_rights, only: %i[show edit update]
    resources :agent_services, only: %i[show destroy]
    resources :user_profiles, only: %i[destroy]
    resources :super_admins, only: %i[index destroy]
    resources :organisations
    resources :services
    resources :motifs
    resources :lieux
    resources :territories, except: %i[new create]
    resources :territory_creation_requests, only: %i[index edit update]
    resources :users
    resources :comptes, only: %i[new create]
    resources :rdvs, only: %i[show]
    resources :prescripteurs, only: %i[show]
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
  namespace :stats, controller: "stats", module: nil do
    get "/", action: "index"
    get :territories
    get :territory
    get :territory_rdvs
    get :lieux_map_data, format: :json
  end

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
    get "agents/sign_out", to: "agents/sessions#destroy" # Utilisé par les clients Oauth pour se déconnecter

    get "agents/edit" => "agents/registrations#edit", as: "edit_agent_registration"
    put "agents" => "agents/registrations#update", as: "agent_registration"
    delete "agents" => "agents/registrations#destroy", as: "delete_agent_registration"

    get "agents/mot_de_passe/edit" => "agents/mot_de_passes#edit", as: "edit_agent_mot_de_passes"
    put "agents/mot_de_passe" => "agents/mot_de_passes#update", as: "agent_mot_de_passes"

    namespace :agents do
      resource :preferences, only: %i[show update]
      resource :calendar_sync, only: %i[show], controller: :calendar_sync do
        resource :caldav_sync, only: %i[show update destroy], controller: :caldav_sync
        resource :webcal_sync, only: %i[show update], controller: :webcal_sync
        resource :outlook_sync, only: %i[show destroy], controller: :outlook_sync
      end
      resources :rdvs, only: %i[show]
      resources :rdv_plans, only: %i[show] do
        member do
          patch :update_agent

          get :edit_starts_at
          patch :update_starts_at

          get :edit_modalites
          patch :update_modalites

          get :edit_motif
          patch :update_motif

          get :edit_user
          post :create_rdv

          get :rdv
        end
      end

      resources :users, only: [] do
        collection do
          get "search"
        end
      end
      resources :agents, only: [] do
        collection do
          get "search"
        end
      end

      resources :territories, only: %i[new create]
      resources :territory_creation_requests, only: %i[new create]
      resources :instance_exports, only: %i[index]
      resources :exports, only: %i[index] do
        get :download
      end
    end

    get "omniauth/microsoft_graph/callback" => "omniauth_callbacks#microsoft_graph"
    get "omniauth/rdvservicepublic/callback" => "admin/instance_exports#oauth_callback"

    get "agents/blog/posts" => "agents/blog/posts#index"
  end

  get "/calendrier/:id", controller: :ics_calendar, action: :show, as: :ics_calendar

  authenticate :agent do
    namespace "admin" do
      namespace :api, defaults: { format: :json } do
        namespace :agenda do
          resources :plage_ouvertures, only: [:index]
          resources :rdvs, only: [:index]
          resources :absences, only: [:index]
        end
      end
      resources :territories, only: %i[edit update show] do
        scope module: "territories" do
          resources :agent_roles, only: %i[update create destroy]
          resources :agent_territorial_access_rights, only: %i[update]
          resources :agent_territorial_roles, only: %i[] do
            collection do
              put :create_or_destroy
            end
          end
          resources :webhook_endpoints, except: %i[show]
          resources :organisations, only: %i[new create index] do
            member do
              patch :close
              get :confirm_reopen
              post :reopen
            end
          end
          resources :agents, only: %i[index new create edit] do
            member do
              put :territory_admin
              patch :update_services
              patch :update_teams
            end
          end
          resources :teams, except: :show
          resources :motifs, only: %i[index new create destroy] do
            collection do
              get :batch_edit
              post :batch_update
            end
            member do
              post :archive
              post :unarchive
            end
          end
          resource :user_fields, only: %i[edit update]
          resource :rdv_fields, only: %i[edit update]
          resource :motif_fields, only: %i[edit update]
          resource :motif_categories, only: %i[update]
          resource :sms_configuration, only: %i[show edit update]
          resources :zone_imports, only: %i[new create]
          resources :zones, only: [:index] # exports only
          resource :services, only: %i[edit update]
          resource :sectorization, only: [:show]
          resources :sectors do
            resources :zones
            resources :sector_attributions, only: %i[new create destroy], as: :attributions
            delete "/zones" => "zones#destroy_multiple"
          end
          get "sectorisation_test" => "sectorisation_tests#search"
        end
      end

      resources :organisations do
        collection do
          get "configuration", to: "organisations/configurations#index"
        end
        get "creneaux_search" => "creneaux_search#index"
        get "creneaux_search/selection_creneaux" => "creneaux_search#selection_creneaux"
        # Lien très utilisé pour la duplication de RDV
        # il permet de reprendre un RDV, éventuellement pour un autre motif
        # https://zammad10.ethibox.fr/#ticket/zoom/3044
        # On le garde pour la rétrocompatibilité après le renommage de la route.
        get "agent_searches", to: redirect(path: "/admin/organisations/%{organisation_id}/creneaux_search")
        get "slots", to: redirect(path: "/admin/organisations/%{organisation_id}/creneaux_search/selection_creneaux")

        resources :instance_exports, only: %i[index new edit update show] do
          member do
            patch :archive_motifs
          end
        end
        resources :lieux, except: :show do
          member do
            post :close
            post :reopen
          end
        end

        resources :motifs do
          member do
            post :archive
            post :unarchive
          end
        end
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
            post :participations_export
            post :export
            get :a_renseigner
          end
        end
        scope module: "organisations" do
          resource :online_booking, only: %i[show edit update] do
            member do
              get :edit_user_type
              patch :update_user_type
            end
          end

          namespace :online_booking do
            resources :motifs, only: %i[show edit update] do
              member do
                post :open
                post :close
              end
            end
          end

          resource :configuration, only: [:show]
          resources :stats, only: :index do
            collection do
              get :rdvs
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
        resources :agent_intervenants, only: %i[update]
        resources :agents, except: %i[show]
        namespace :planning do
          get :agenda, to: "agendas#show"
          put :toggle_displays, to: "agendas#toggle_displays"

          resources :absences
          resources :plage_ouvertures do
            collection do
              get :calendar
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
        get "support", to: "static_pages#support"
        resource :prescription, only: [], controller: "prescription" do
          get "search_creneau"
          get "user_selection"
          get "recapitulatif"
          post "create_rdv"
          get "confirmation"
        end
      end
    end
  end
  authenticated :agent do
    root to: "agents/pages#home", as: :authenticated_agent_root
  end
  get "agents/agenda", to: "agents/agendas#show"

  scope path: "prescripteur", as: "prescripteur", controller: "prescripteur_rdv_wizard" do
    get "start"
    get "new_prescripteur"
    post "store_prescripteur_in_session"
    get "new_beneficiaire"
    post "create_rdv"
    get "confirmation"
  end

  %w[mds accessibilite mentions_legales cgu cgu_agent politique_de_confidentialite domaines].each do |page_name|
    get page_name => "static_pages##{page_name}"
  end

  get "contact", to: redirect("/aide/aiguillage_role", status: 302) # temporary redirect in case we rollback
  namespace :aide do
    get "aiguillage_role" => "pages#aiguillage_role"
    get "aiguillage_usager" => "pages#aiguillage_usager"
    resource :demande_support, only: %i[new create]
  end

  get "/.well-known/microsoft-identity-association" => "static_pages#microsoft_domain_verification", format: :json

  get "health_check" => "health#db_connection"
  get "health/jobs_queues" => "health#jobs_queues"
  get "health/jobs_scheduled" => "health#jobs_scheduled"

  get "/budget", to: redirect("https://pad.numerique.gouv.fr/rHMnemklQm6Sww5yVCI9ow?view#RDV-Service-Public", status: 302)

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
    params.values.any? ? "?#{params.to_query}" : ""
  end

  # short public link
  get "org/:organisation_id(/:org_slug)" => "search#public_link_with_internal_organisation_id", as: :public_link_to_org
  get "org/ext/:territory/:organisation_external_id(/:org_slug)" => "search#public_link_with_external_organisation_id", as: :public_link_to_external_org
  get "/creneaux", to: "search#public_link_to_creneaux"

  # resin public link
  get "resin/:external_organisation_ids" => "search#resin"

  get "prendre_rdv_prescripteur" => "search#prescripteur", as: :prendre_rdv_prescripteur

  ##

  get "accueil_mds", to: redirect("presentation_agent", status: 307)
  get "presentation_agent" => "static_pages#presentation_for_agents"

  root "search#home"

  get "/prendre_rdv", to: "search#search_rdv"

  # temporary route after admin namespace introduction
  get "/organisations/*rest", to: redirect("admin/organisations/%{rest}")
  post "/inbound_emails/sendinblue", controller: :inbound_emails, action: :brevo # TODO: supprimer après la transition
  post "/inbound_emails/brevo", controller: :inbound_emails, action: :brevo

  # This route redirects invitations to rdv-insertion so that rdv-insertion
  # can use rdvs domain name in their emails
  get "/i/r/:uuid", to: redirect { |path_params, _|
    "#{ENV['RDV_INSERTION_HOST']}/r/#{path_params[:uuid]&.strip}"
  }

  if Rails.env.development?
    # LetterOpener
    mount LetterOpenerWeb::Engine, at: "/letter_opener"
  end

  ## APIs
  draw :api

  # Évite de casser les anciennes routes vers l'agenda, les plages et les absences
  draw :legacy_planning_routes_redirects

  match "/404", to: "errors#not_found", via: :all
  match "/500", to: "errors#internal_server_error", via: :all

  get "robots.txt" => "robots#robots"
end
