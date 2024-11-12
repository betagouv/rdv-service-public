RSpec.describe "Création de comptes de conseillers numériques" do
  let(:params) do
    {
      agent: {
        email: "francis.factice@france-service.fr",
        first_name: "Francis",
        last_name: "Factice",
        external_id: "123456",
      },
      organisation: {
        external_id: "123456",
        name: "ANCT",
      },
      lieux: [{
        name: "Bureaux PIX",
        address: "21 rue des Ardennes, Paris, 75019",
      }],
    }
  end

  before do
    create(:territory, :conseillers_numeriques)
    create(:service, :conseiller_numerique)
    stub_request(
      :get,
      "https://api-adresse.data.gouv.fr/search/?postcode=75019&q=21%20rue%20des%20Ardennes,%20Paris,%2075019"
    ).to_return(status: 200, body: file_fixture("geocode_result.json").read, headers: {})
  end

  context "when the api key is configured properly" do
    stub_env_with(COOP_MEDIATION_NUMERIQUE_API_KEY: "coop-mediation-numerique-api-test-key-123456")
    context "without the api key header" do
      before do
        post "/api/coop-mediation-numerique/accounts", params: params
      end

      it "returns a 401 response" do
        expect(response.status).to eq 401
        expect(response.parsed_body).to eq({ "errors" => ["Authentification invalide"] })
      end
    end

    context "with the wrong api key" do
      before do
        post "/api/coop-mediation-numerique/accounts", params: params, headers: { "X-COOP-MEDIATION-NUMERIQUE-API-KEY": "wrong key" }
      end

      it "returns a 401 response" do
        expect(response.status).to eq 401
        expect(response.parsed_body).to eq({ "errors" => ["Authentification invalide"] })
      end
    end

    context "with the correct api key" do
      before do
        post "/api/coop-mediation-numerique/accounts", params: params, headers: { "X-COOP-MEDIATION-NUMERIQUE-API-KEY": "coop-mediation-numerique-api-test-key-123456" }
      end

      it "returns a 201 response" do
        expect(response.status).to eq 201
        expect(response.parsed_body.keys).to eq ["id"]
      end
    end
  end

  context "when the api key is not configured" do
    stub_env_with(COOP_MEDIATION_NUMERIQUE_API_KEY: nil)

    it "raises an error" do
      expect do
        post "/api/coop-mediation-numerique/accounts", params: params, headers: { "X-COOP-MEDIATION-NUMERIQUE-API-KEY": "test-api-key" }
      end.to raise_error(KeyError)

      expect(response).to be_nil
    end
  end
end
