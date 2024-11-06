class Api::AccountsController < ActionController::Base
  respond_to :json
  skip_forgery_protection # L'authentification par clé d'api nous protège des csfr

  before_action :authenticate_with_api_key

  def create
    AddConseillerNumerique.process!(params.require(
                                      {
                                        agent: %i[
                                          first_name last_name email external_id
                                        ],
                                        organisation: %i[
                                          name address external_id
                                        ],
                                      }
                                    ))

    render json: {}, status: :created
  end

  private

  def authenticate_with_api_key
    authorized = ActiveSupport::SecurityUtils.secure_compare(
      request.headers["X-CONUM-API-KEY"] || "",
      ENV.fetch("CONUM_API_KEY")
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
