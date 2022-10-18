# frozen_string_literal: true

namespace :api do
  namespace :v1 do
    mount_devise_token_auth_for "AgentWithTokenAuth", at: "auth"
    resources :absences, except: %i[new edit]
    resources :agents, only: %i[index]
    resources :users, only: %i[create index show update] do
      get :invite, on: :member
      post :invite, on: :member
    end
    resources :user_profiles, only: [:create]
    resources :organisations, only: %i[index] do
      resources :users, only: %i[index show]
      resources :motifs, only: %i[index]
      resources :rdvs, only: %i[index]
    end

    resources :invitations, param: "token", only: [:show]
  end
end
