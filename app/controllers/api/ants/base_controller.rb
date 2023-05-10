# frozen_string_literal: true

class Api::Ants::BaseController < ActionController::Base
  respond_to :json

  before_action do
    unless ActiveSupport::SecurityUtils.secure_compare(ENV["ANTS_API_AUTH_TOKEN"], request.headers["X-HUB-RDV-AUTH-TOKEN"] || "")
      render(
        status: :unauthorized,
        json: { error: "X-HUB-RDV-AUTH-TOKEN header is missing or invalid" }.to_json
      )
    end
  end
end
