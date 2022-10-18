# frozen_string_literal: true

namespace :public_api do
  namespace :v1 do
    resources :public_links, only: [:index]
  end

  # This one has been published before versioning the public API:
  get :public_links, to: "v1/public_links#index"
end
