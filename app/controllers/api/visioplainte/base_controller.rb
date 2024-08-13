class Api::Visioplainte::BaseController < ActionController::Base # rubocop:disable Rails/ApplicationController
  respond_to :json

  before_action :authenticate_with_api_token

  def authenticate_with_api_token
    authorized = ActiveSupport::SecurityUtils.secure_compare(
      request.headers["X-VISIOPLAINTE-API-KEY"] || "",
      ENV.fetch("VISIOPLAINTE_API_KEY")
    )

    unless authorized
      render(
        status: :unauthorized,
        json: {
          errors: ["Authentification invalide"],
        }
      )
    end
  end
end
