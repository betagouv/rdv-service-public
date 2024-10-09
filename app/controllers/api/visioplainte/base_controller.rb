class Api::Visioplainte::BaseController < ActionController::Base # rubocop:disable Rails/ApplicationController
  respond_to :json
  skip_forgery_protection # L'authentification par clé d'api nous protège des csfr

  before_action :authenticate_with_api_key

  GENDARMERIE_SERVICE_NAME = "Gendarmerie Nationale".freeze

  def authenticate_with_api_key
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
