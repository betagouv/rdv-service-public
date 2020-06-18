require 'omniauth-oauth2'

module OmniAuth
  module Strategies
    class Franceconnect < OmniAuth::Strategies::OAuth2

      option :client_options, {
        :site => 'https://fcp.integ01.dev-franceconnect.fr',
        :authorize_url => 'https://fcp.integ01.dev-franceconnect.fr/api/v1/authorize',
        :token_url => 'https://fcp.integ01.dev-franceconnect.fr/api/v1/token'
      }

      def authorize_params
        super.tap do |params|
          %w[scope client_options].each do |v|
            if request.params[v]
              params[v.to_sym] = request.params[v]
            end
            params[:nonce] = "1234"
          end
        end
      end

      uid { raw_info['id'].to_s }

      info do

        puts ('raw_info')
        puts (raw_info)
        {
          'email' => email,
          'raw' => raw_info,
          'scope' => scope
        }
      end

      extra do
        {:raw_info => raw_info, :scope => scope }
      end

      def raw_info
        access_token.options[:mode] = :header
        @raw_info ||= access_token.get('https://fcp.integ01.dev-franceconnect.fr/api/v1/userinfo?schema=openid,profile,email').parsed
      end

      def email
        "yolo@thomas.fr"
        #(email_access_allowed?) ? primary_email : raw_info['email']
      end

      def scope
        access_token['scope']
      end

      def callback_url
        full_host + script_name + callback_path
      end
    end
  end
end

#OmniAuth.config.add_camelization 'franceconnect', 'Franceconnect'
