# frozen_string_literal: true

namespace :api do
  namespace :v1 do
    # Need agent authentication to
    mount_devise_token_auth_for "AgentWithTokenAuth", at: "auth"
    resources :absences, except: %i[new edit]
    resources :agents, only: %i[index]
    resources :users, only: %i[create index show update] do
      get :invite, on: :member
      post :invite, on: :member
    end
    resource :user_profiles, only: %i[create destroy]
    resource :referent_assignations, only: %i[create destroy]
    resources :organisations, only: %i[index show update] do
      resources :webhook_endpoints, only: %i[index create update]
      resources :users, only: %i[index show]
      resources :motifs, only: %i[index]
      resources :rdvs, only: %i[index]
    end
    resources :invitations, param: "token", only: [:show]

    # Doesn't need authentication
    resources :public_links, only: [:index]
  end
end

# This one has been published before versioning the public API and unification with auth API:
get "public_api/public_links", to: "api/v1/public_links#index"
