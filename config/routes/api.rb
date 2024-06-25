namespace :api do
  namespace :v1 do
    # Need agent authentication to
    mount_devise_token_auth_for "AgentWithTokenAuth", at: "auth"
    resources :absences, except: %i[new edit]
    resources :agents, only: %i[index]
    resources :users, only: %i[create index show update] do
      post :rdv_invitation_token, to: "users#rdv_invitation_token", on: :member
    end
    resource :user_profiles, only: %i[create destroy]
    resource :referent_assignations, only: %i[create destroy]
    resources :organisations, only: %i[index show update] do
      resources :webhook_endpoints, only: %i[index create update]
      resources :users, only: %i[index show]
      resources :motifs, only: %i[index]
      resources :rdvs, only: %i[index]
    end
    resources :participations, only: %i[update]
    # Doesn't need authentication
    resources :public_links, only: [:index]
  end

  namespace :ants do
    get "getManagedMeetingPoints", to: "editor#get_managed_meeting_points"
    get "availableTimeSlots", to: "editor#available_time_slots"
    get "searchApplicationIds", to: "editor#search_application_ids"
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
    resources :motif_categories, only: %i[create]
    resources :motif_category_territories, only: %i[create]
  end
end

# This one has been published before versioning the public API and unification with auth API:
get "public_api/public_links", to: "api/v1/public_links#index"
