RSpec.describe Menshen::ExchangeToken do
  subject(:service) { described_class.new(subject_token: "fake proconnect access token") }

  stub_env_with(
    MENSHEN_BASE_URL: "https://menshen.example.org",
    MENSHEN_CLIENT_ID: "rdv-service-public",
    MENSHEN_CLIENT_SECRET: "un faux secret de test",
    MENSHEN_AUDIENCE: "visio"
  )

  describe "#call" do
    it "échange le token ProConnect contre un jeton Menshen" do
      stub_request(:post, "https://menshen.example.org/auth/token/exchange/")
        .with(
          basic_auth: ["rdv-service-public", "un faux secret de test"],
          body: {
            "grant_type" => "urn:ietf:params:oauth:grant-type:token-exchange",
            "subject_token" => "fake proconnect access token",
            "subject_token_type" => "urn:ietf:params:oauth:token-type:access_token",
            "audience" => "visio",
          }
        )
        .to_return(
          status: 200,
          body: { access_token: "fake menshen token", expires_in: 3600 }.to_json,
          headers: { "Content-Type" => "application/json" }
        )

      expect(service.call).to eq("access_token" => "fake menshen token", "expires_in" => 3600)
    end

    context "quand Menshen retourne une erreur" do
      it "lève une ApiError" do
        stub_request(:post, "https://menshen.example.org/auth/token/exchange/")
          .to_return(status: 400, body: "invalid_grant")

        expect { service.call }.to raise_error(Menshen::ExchangeToken::ApiError, /HTTP 400/)
      end
    end
  end
end
