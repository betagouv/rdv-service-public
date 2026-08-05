RSpec.describe ProConnectOpenIdClient::Auth do
  stub_env_for_proconnect

  subject(:auth) { described_class.new(client_id: "client_id", client_secret: "client_secret") }

  describe "#redirect_url" do
    subject(:scope_param) do
      url = auth.redirect_url("https://example.org/callback")
      Rack::Utils.parse_query(URI.parse(url).query)["scope"]
    end

    it "requests the Visio scopes" do
      expect(scope_param).to include("lasuite_visio")
      expect(scope_param).to include("lasuite_visio:rooms:create")
    end

    context "when VISIO_NUMERIQUE_DISABLED is set" do
      stub_env_with(VISIO_NUMERIQUE_DISABLED: "true")

      it "doesn't request the Visio scopes" do
        expect(scope_param).not_to include("lasuite_visio")
      end

      it "still requests the other scopes" do
        expect(scope_param).to include("openid")
        expect(scope_param).to include("siret")
      end
    end
  end
end
