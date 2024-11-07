class Api::AccountsController < ActionController::Base
  respond_to :json
  skip_forgery_protection # L'authentification par clé d'api nous protège des csfr

  before_action :authenticate_with_api_key

  def create
    agent = AddConseillerNumerique.process!(
      agent: params.require(:agent).permit(%i[first_name last_name email external_id]),
      organisation: params.require(:organisation).permit(%i[name external_id]),
      lieux: params.permit(lieux: %i[name address]).require(:lieux)
    )

    render json: { id: agent.id }, status: :created
  end

  private

  def authenticate_with_api_key
    authorized = ActiveSupport::SecurityUtils.secure_compare(
      request.headers["X-COOP-MEDIATION-NUMERIQUE-API-KEY"] || "",
      ENV.fetch("COOP_MEDIATION_NUMERIQUE_API_KEY")
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
