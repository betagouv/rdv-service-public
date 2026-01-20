RSpec.describe ProConnect do
  stub_env_with(PRO_CONNECT_BASE_URL: "https://fca.integ01.dev-agentconnect.fr/api/v2")

  describe ".open_id_config_discover!" do
    context "when ProConnect is not accessible" do
      before do
        stub_request(:get, "https://fca.integ01.dev-agentconnect.fr/api/v2/.well-known/openid-configuration")
          .to_return(status: 500, body: "", headers: {})
      end

      it "raises an error" do
        expect { described_class.open_id_config_discover! }.to(raise_error(OpenIDConnect::Discovery::DiscoveryFailed))
      end
    end

    context "when ProConnect is accessible" do
      before do
        stub_request(:get, "https://fca.integ01.dev-agentconnect.fr/api/v2/.well-known/openid-configuration")
          .to_return(status: 200, body: File.read(Rails.root.join("spec/fixtures/pro_connect/openid-configuration.json").to_s), headers: {})
      end

      it "returns the config" do
        expect(described_class.open_id_config_discover!).to have_attributes({ id_token_signing_alg_values_supported: %w[HS256 ES256 RS256] })
      end
    end
  end

  describe "client_id" do
    it "works" do
      expect { described_class.client_id(Domain::RDV_SOLIDARITES) }.to    raise_error("ProConnect client id not found for RDV_SOLIDARITES")
      expect { described_class.client_id(Domain::RDV_AIDE_NUMERIQUE) }.to raise_error("ProConnect client id not found for RDV_AIDE_NUMERIQUE")
      expect { described_class.client_id(Domain::RDV_SERVICE_PUBLIC) }.to raise_error("ProConnect client id not found for RDV_SERVICE_PUBLIC")

      with_modified_env(PRO_CONNECT_RDVS_CLIENT_ID: "ok")   { expect(described_class.client_id(Domain::RDV_SOLIDARITES)).to eq("ok") }
      with_modified_env(PRO_CONNECT_RDVAN_CLIENT_ID: "ok")  { expect(described_class.client_id(Domain::RDV_AIDE_NUMERIQUE)).to eq("ok") }
      with_modified_env(PRO_CONNECT_RDVSP_CLIENT_ID: "ok")  { expect(described_class.client_id(Domain::RDV_SERVICE_PUBLIC)).to eq("ok") }
    end
  end
end
