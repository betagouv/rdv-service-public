module FranceConnect
  module Utils
    def france_connect_authorization_uri
      client = OpenIDClient.new

      client.authorization_uri(
        scope: [:openid, :profile, :email],
        state: SecureRandom.hex(16),
        nonce: SecureRandom.hex(16),
        acr_values: 'eidas1'
      )
    end

    def france_connect_retrieve_user_infos(code)
      client = OpenIDClient.new(code)

      user_info = client.access_token!(client_auth_method: :secret)
        .userinfo!
        .raw_attributes

      OpenStruct.new(
        gender: user_info[:gender],
        given_name: user_info[:given_name],
        family_name: user_info[:family_name],
        email_france_connect: user_info[:email],
        birthdate: user_info[:birthdate],
        birthplace: user_info[:birthplace],
        france_connect_particulier_id: user_info[:sub]
      )
    end
  end

  class OpenIDClient < OpenIDConnect::Client
    def initialize(code = nil)
      super(
        identifier: ENV['FRANCECONNECT_APP_ID'],
        secret: ENV['FRANCECONNECT_APP_SECRET'],
        redirect_uri: "#{ENV['HOST']}/france_connect/callback",
        authorization_endpoint: "#{ENV['FRANCECONNECT_BASE_URL']}/api/v1/authorize",
        token_endpoint: "#{ENV['FRANCECONNECT_BASE_URL']}/api/v1/token",
        userinfo_endpoint: "#{ENV['FRANCECONNECT_BASE_URL']}/api/v1/userinfo",
        logout_endpoint: "#{ENV['FRANCECONNECT_BASE_URL']}/api/v1/logout",
      )

      self.authorization_code = code if code.present?
    end
  end
end
