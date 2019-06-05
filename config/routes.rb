Rails.application.routes.draw do
  ## ADMIN ##
  devise_for :super_admins, controllers: { omniauth_callbacks: 'super_admins/omniauth_callbacks' }

  delete 'admin/sign_out' => 'super_admins/sessions#destroy'

  namespace :admin do
    resources :pros
    resources :super_admins
    resources :organisations
    resources :sites
    root to: "pros#index"

    authenticate :super_admin do
      match "/delayed_job" => DelayedJobWeb, :anchor => false, :via => [:get, :post]
    end
  end

  ## APP ##
  devise_for :pros, controllers: { registrations: 'pros/registrations', invitations: 'pros/invitations' }
  resources :pros, only: [:show, :destroy] do
    post :reinvite, on: :member
  end
  namespace :pros do
    resources :full_subscriptions, only: [:new, :create]
    resources :permissions, only: [:edit, :update]
  end

  authenticated :pro do
    root to: 'agendas#index', as: :authenticated_root
    resources :organisations, except: :destroy do
      resources :sites, except: :index
      resources :pros
      resources :specialites
    end
  end

  { disclaimer: 'mentions_legales', terms: 'cgv' }.each do |k, v|
    get v => "static_pages##{k}"
  end
  get 'accueil_mds' => "welcome#welcome_pro"
  root 'welcome#index'
end
