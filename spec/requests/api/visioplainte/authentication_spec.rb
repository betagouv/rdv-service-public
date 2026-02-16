RSpec.describe "Authentification" do
  stub_env_with(DB_SEEDS_USERS_AND_AGENTS_PASSWORD: "Rdvservicepublictest1!")

  let(:creneaux_params) do
    {
      service: "Gendarmerie",
      date_debut: "2024-08-19",
      date_fin: "2024-08-25",
    }
  end

  context "when the api key is configured properly" do
    stub_env_with(VISIOPLAINTE_API_KEY: "visioplainte-api-test-key-123456")
    context "without the api key header" do
      before do
        get "/api/visioplainte/creneaux"
      end

      it "returns a 401 response" do
        expect(response.status).to eq 401
        expect(response.parsed_body).to eq({ "errors" => ["Authentification invalide"] })
      end
    end

    context "with the wrong api key" do
      before do
        get "/api/visioplainte/creneaux", headers: { "X-VISIOPLAINTE-API-KEY": "wrong key" }
      end

      it "returns a 401 response" do
        expect(response.status).to eq 401
        expect(response.parsed_body).to eq({ "errors" => ["Authentification invalide"] })
      end
    end

    context "with the correct api key" do
      before do
        load Rails.root.join("db/seeds/visioplainte.rb")
        get "/api/visioplainte/creneaux", headers: { "X-VISIOPLAINTE-API-KEY": "visioplainte-api-test-key-123456" }, params: creneaux_params
      end

      it "returns a 200 response" do
        expect(response.status).to eq 200
        expect(response.parsed_body.keys).to eq ["creneaux"]
      end
    end
  end

  context "when the api key is not configured" do
    stub_env_with(VISIOPLAINTE_API_KEY: nil)

    it "raises an error" do
      expect do
        get "/api/visioplainte/creneaux", headers: { "X-VISIOPLAINTE-API-KEY": "test-api-key" }
      end.to raise_error(KeyError)

      expect(response).to be_nil
    end
  end

  context "with a read-only api key" do
    stub_env_with(VISIOPLAINTE_API_KEY_READ_ONLY: "visioplainte-api-test-key-read-only-456789")
    stub_env_with(VISIOPLAINTE_API_KEY: "visioplainte-api-test-key-123456")

    context "on an endpoint that only reads data" do
      before do
        load Rails.root.join("db/seeds/visioplainte.rb")
        get "/api/visioplainte/creneaux", headers: { "X-VISIOPLAINTE-API-KEY": "visioplainte-api-test-key-read-only-456789" }, params: creneaux_params
      end

      it "returns a 200 response" do
        expect(response.status).to eq 200
        expect(response.parsed_body.keys).to eq ["creneaux"]
      end
    end

    context "on an endpoint that modifies data" do
      before do
        load Rails.root.join("db/seeds/visioplainte.rb")
        post "/api/visioplainte/rdvs", headers: { "X-VISIOPLAINTE-API-KEY": "visioplainte-api-test-key-read-only-456789" }
      end

      it "returns a 401 response" do
        expect(response.status).to eq 401
        expect(response.parsed_body).to eq({ "errors" => ["Authentification invalide"] })
      end
    end
  end
end
