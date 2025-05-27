module FranceConnectV2Stubs
  extend RSpec::Mocks::ExampleMethods # pour appeler #allow et #receive dans des méthodes de module

  def self.stub_and_run_discover_request
    WebMock.stub_request(:get, "https://fcp-low.integ01.dev-franceconnect.fr/api/v2/.well-known/openid-configuration")
      .to_return(status: 200, body: File.read(Rails.root.join("spec/fixtures/france_connect_v2/openid-configuration.json").to_s), headers: {})
    load Rails.root.join("config/initializers/france_connect_v2.rb").to_s
  end

  def self.stub_callback_requests(code, user_info)
    stub_and_run_discover_request

    stub_token_request(code)

    userinfo_encoded_response_body = "fake_userinfo_encoded_response_body"

    stub_userinfo_request(userinfo_encoded_response_body)

    jwks_json = File.read(Rails.root.join("spec/fixtures/france_connect_v2/jwks.json").to_s)
    WebMock.stub_request(:get, "https://fcp-low.integ01.dev-franceconnect.fr/api/v2/jwks").to_return(status: 200, body: jwks_json, headers: {})

    jwks = JSON.parse(jwks_json)

    # En enregistrant puis en rejouant une vrai requête, on a une erreur  JWT::ExpiredSignature: Signature has expired
    # Le plus pragmatique pour cette spec semble donc d'être de stubber le JWT.decode
    allow(JWT).to receive(:decode).with(
      userinfo_encoded_response_body, nil, true,
      algorithms: "ES256",
      jwks: jwks["keys"]
    ).and_return([user_info])
  end

  def self.stub_token_request(code)
    WebMock.stub_request(:post, "https://fcp-low.integ01.dev-franceconnect.fr/api/v2/token").with(
      body: {
        "client_id" => "ec41582-1d60-4f11-a63b-d8abaece16aa",
        "client_secret" => "un faux secret de test",
        "code" => code,
        "grant_type" => "authorization_code",
        "redirect_uri" => "http://test.host/franceconnect_v2/callback",
      },
      headers: {
        "Content-Type" => "application/x-www-form-urlencoded",
      }
    ).to_return(status: 200, body: {
      id_token: "fake france connect v2 id token",
      access_token: "fake france connect v2 access token",
    }.to_json, headers: {})

    allow(OpenIDConnect::ResponseObject::IdToken).to receive(:decode).and_return(
      instance_double(OpenIDConnect::ResponseObject::IdToken, verify!: true)
    )
  end

  def self.stub_userinfo_request(response_body)
    WebMock.stub_request(:get, "https://fcp-low.integ01.dev-franceconnect.fr/api/v2/userinfo?schema=openid")
      .with(
        headers: {
          "Authorization" => "Bearer fake france connect v2 access token",
          "Expect" => "",
          "User-Agent" => "Typhoeus - https://github.com/typhoeus/typhoeus",
        }
      )
      .to_return(status: 200, body: response_body, headers: {})
  end
end
