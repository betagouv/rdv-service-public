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
            "scope" => "action:create-meet-room",
          }
        )
        .to_return(
          status: 200,
          body: { access_token: "fake menshen token", expires_in: 3600 }.to_json,
          headers: { "Content-Type" => "application/json" }
        )

      expect(service.call).to eq("access_token" => "fake menshen token", "expires_in" => 3600)
    end

    it "n'expose ni le client secret ni le jeton Menshen dans les breadcrumbs Sentry" do
      stub_request(:post, "https://menshen.example.org/auth/token/exchange/")
        .to_return(
          status: 200,
          body: { access_token: "fake menshen token", expires_in: 3600 }.to_json,
          headers: { "Content-Type" => "application/json" }
        )

      service.call
      Sentry.capture_message("woops")

      request_breadcrumb, response_breadcrumb = sentry_events.last.breadcrumbs.compact
      expect(request_breadcrumb.data[:headers]["Authorization"]).to eq("[SCRUBBED]")
      expect(request_breadcrumb.data[:body]).to eq("[SCRUBBED]")
      expect(response_breadcrumb.data[:body]).to eq("[SCRUBBED]")
    end

    context "quand Menshen retourne une erreur 4xx" do
      it "lève une ClientError" do
        stub_request(:post, "https://menshen.example.org/auth/token/exchange/")
          .to_return(status: 400, body: "invalid_grant")

        expect { service.call }.to raise_error(Menshen::ExchangeToken::ClientError, /HTTP 400/)
      end
    end

    context "quand Menshen retourne une erreur 5xx" do
      it "lève une ApiError qui n'est pas une ClientError" do
        stub_request(:post, "https://menshen.example.org/auth/token/exchange/")
          .to_return(status: 503, body: "Service Unavailable")

        expect { service.call }.to raise_error(Menshen::ExchangeToken::ApiError, /HTTP 503/) do |error|
          expect(error).not_to be_a(Menshen::ExchangeToken::ClientError)
        end
      end
    end
  end
end
