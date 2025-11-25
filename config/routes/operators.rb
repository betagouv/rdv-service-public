devise_for :operator_managers

namespace :operators do
  root to: "main#index"

  delete "sign_out" => "operators/sessions#destroy"
end
