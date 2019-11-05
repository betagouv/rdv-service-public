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
    resources :organisations do
      post :default_configuration, on: :member
    end
    resources :lieux
    resources :services
    resources :motifs
    resources :users
    resources :rdvs
    resources :plage_ouvertures
    resources :absences
    root to: "agents#index"

    authenticate :super_admin do
      match "/delayed_job" => DelayedJobWeb, anchor: false, via: [:get, :post]
    end
  end

  ## APP ##
  devise_for :users, controllers: { registrations: 'users/registrations' }

  namespace :users do
    resources :rdvs, only: [:index, :new, :create] do
      get :confirmation
    end
  end

  authenticated :user do
    get "/users/rdvs", to: 'users/rdvs#index', as: :authenticated_user_root
    get "/users/informations", to: 'users/users#edit'
    patch "users/informations", to: 'users/users#update'
  end

  devise_for :agents, controllers: { invitations: 'agents/invitations' }

  as :agent do
    get 'agents/edit' => 'agents/registrations#edit', as: 'edit_agent_registration'
    put 'agents' => 'agents/registrations#update', as: 'agent_registration'
  end

  authenticated :agent do
    root to: 'organisations#index', as: :authenticated_agent_root
    resources :organisations, only: [:show, :index] do
      resources :lieux, except: :show
      resources :motifs, except: :show
      resources :plage_ouvertures, except: :show
      resources :absences, except: :show

      resources :agents, only: [:index, :destroy] do
        post :reinvite, on: :member
      end

      namespace :agents do
        resources :full_subscriptions, only: [:new, :create]
        resources :permissions, only: [:edit, :update]
      end

      resources :users, except: :show, controller: 'organisations/users' do
        post :invite, on: :member
        get :link_to_organisation, on: :member
      end

      resources :rdvs, except: [:create, :new], controller: 'agents/rdvs' do
        patch :status, on: :member
      end

      resources :agent_searches, only: :index, module: "agents/creneaux" do
        get :by_lieu, on: :collection
      end

      [:first_steps, :second_steps, :third_steps].each do |step|
        resources step, only: [:new, :create], module: "agents/rdvs"
      end
    end
  end

  { disclaimer: 'mentions_legales', terms: 'cgv' }.each do |k, v|
    get v => "static_pages##{k}"
  end

  get 'accueil_mds' => "welcome#welcome_agent"
  post '/' => "welcome#search"
  get 'departement/:departement', to: "welcome#welcome_departement", as: "welcome_departement"
  post 'departement/:departement' => "welcome#search_departement"
  get 'departement/:departement/:motif', to: "welcome#welcome_motif", as: "welcome_motif"
  resources :creneaux, only: [:index]
  root 'welcome#index'
end
