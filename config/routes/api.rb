namespace :api do
  namespace :v1 do
    # Need agent authentication to
    mount_devise_token_auth_for "AgentWithTokenAuth", at: "auth"
    resources :absences, except: %i[new edit]
    resources :plage_ouvertures, only: %i[create]
    resources :agents, only: %i[index create]
    resources :lieux, only: %i[index create]
    get "agents/me", to: "agents#me"
    resources :users, only: %i[create index show update] do
      post :rdv_invitation_token, to: "users#rdv_invitation_token", on: :member
    end
    resource :user_profiles, only: %i[create destroy]
    resource :referent_assignations, only: %i[create destroy]
    resources :organisations, only: %i[index show update create] do
      resources :webhook_endpoints, only: %i[index create update]
      resources :users, only: %i[index show]
      resources :motifs, only: %i[index]
      resources :rdvs, only: %i[index]
    end
    resources :motifs, only: %i[create]
    resources :rdvs, only: %i[index create] do
      patch :update_status
    end
    resources :participations, only: %i[update]
    resources :rdv_plans, only: %i[create show]
    resources :teams, only: %i[index]
  end

  namespace :ants do
    get "getManagedMeetingPoints", to: "editor#get_managed_meeting_points"
    get "availableTimeSlots", to: "editor#available_time_slots"
    get "searchApplicationIds", to: "editor#search_application_ids"
  end

  namespace :justice do
    get "lieux", to: "lieux#index"
  end

  namespace :anct do
    get "metrics", to: "metrics#index"
  end

  namespace :rdvinsertion do
    resources :invitations, only: [] do
      get "creneau_availability", to: "invitations#creneau_availability", on: :collection
    end
    resource :user_profiles, only: [] do
      post :create_many, on: :collection
    end
    resource :referent_assignations, only: [] do
      post :create_many, on: :collection
    end
    resources :users, only: %i[show] do
      resources :referent_assignations, only: %i[index]
    end
    resources :motif_categories, only: %i[create]
    resources :motif_category_territories, only: %i[create]
  end

  namespace :visioplainte do
    resources :guichets, only: %i[index]
    resources :plages_ouverture, only: %i[index]
    resources :creneaux, only: %i[index] do
      collection do
        get :prochain
      end
    end
    resources :rdvs, only: %i[create destroy index] do
      member do
        put :cancel
      end
    end

    # Une route pour réinitialiser les données en staging
    if ENV["RDV_SOLIDARITES_INSTANCE_NAME"] == "STAGING"
      post :reset, to: "base#reset"
    end
  end

  post "/coop-mediation-numerique/accounts", to: "coop_mediation_numerique/accounts#create"
end
