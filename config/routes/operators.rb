devise_for :operator_managers, controllers: { sessions: "operators/sessions" }

devise_scope :operator_manager do
  get "operators/sign_out" => "operators/sessions#destroy", as: :operator_sign_out
end

namespace :operators do
  root to: "main#index"
  resources :configuration
  resources :espaces
end
