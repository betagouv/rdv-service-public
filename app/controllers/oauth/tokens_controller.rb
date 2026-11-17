module Oauth
  class TokensController < Doorkeeper::TokensController
    # Chaque application n'est autorisée à émettre des jetons que via le grant_type
    # renseigné dans sa colonne `grant_type` (authorization_code ou client_credentials),
    # même si les deux grants sont globalement activés.
    # Le renouvellement par refresh_token reste géré par Doorkeeper (transverse aux deux grants).
    GRANT_TYPES_RESERVES = %w[authorization_code client_credentials].freeze

    before_action :check_grant_type_matches_application, only: :create # rubocop:disable Rails/LexicallyScopedActionFilter

    private

    def check_grant_type_matches_application
      return if GRANT_TYPES_RESERVES.exclude?(params[:grant_type])

      # Pour client_credentials, le client_secret ne doit passer que dans le body de la requête :
      # un header Authorization est loggé par défaut par de nombreux middlewares/APM
      if params[:grant_type] == "client_credentials" && request.authorization.to_s.start_with?("Basic ")
        error = Doorkeeper::OAuth::ErrorResponse.new(name: :invalid_client)
        return render json: error.body, status: error.status
      end

      credentials = Doorkeeper::OAuth::Client::Credentials.from_request(request, *Doorkeeper.config.client_credentials_methods)
      application = Doorkeeper::Application.by_uid(credentials.uid) if credentials&.uid.present?
      return if application.blank?
      return if application.grant_type == params[:grant_type]

      error = Doorkeeper::OAuth::ErrorResponse.new(name: :unauthorized_client)
      render json: error.body, status: error.status
    end
  end
end
