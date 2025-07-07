# Voir doc FranceConnect : https://docs.partenaires.franceconnect.gouv.fr/fs/fs-pilotage/
module FranceConnectV2OpenIdClient
  class Auth
    def initialize(client_id:)
      @client_id = client_id

      @state = SecureRandom.base58(32)
      @nonce = SecureRandom.base58(32)
    end

    attr_reader :state, :nonce

    def redirect_url(callback_url)
      # https://docs.partenaires.franceconnect.gouv.fr/fs/fs-technique/fs-technique-endpoints/#authorization-endpoint
      query_params = {
        response_type: "code",
        client_id: @client_id,
        redirect_uri: callback_url,
        scope: "email openid birthdate given_name family_name preferred_username",
        state: state,
        nonce: nonce,
        acr_values: "eidas1",
      }.compact_blank

      "#{ENV['FRANCECONNECT_V2_BASE_URL']}/authorize?#{query_params.to_query}"
    end
  end
end
