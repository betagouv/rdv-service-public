RSpec.describe "Authentification" do
  context "when the api key is configured properly" do
    stub_env_with(VISIOPLAINTE_API_KEY: "visioplainte-api-test-key-123456")

    context "without the api key header" do
      before do
        get "/api/visioplainte/creneaux"
      end

      it "returns a 401 response" do
        expect(response.status).to eq 401
        expect(JSON.parse(response.body)).to eq({ "errors" => ["Authentification invalide"] })
      end
    end

    context "with the wrong api key" do
      before do
        get "/api/visioplainte/creneaux", headers: { "X-VISIOPLAINTE-API-KEY": "wrong key" }
      end

      it "returns a 401 response" do
        expect(response.status).to eq 401
        expect(JSON.parse(response.body)).to eq({ "errors" => ["Authentification invalide"] })
      end
    end

    context "with the correct api key" do
      before do
        get "/api/visioplainte/creneaux", headers: { "X-VISIOPLAINTE-API-KEY": "visioplainte-api-test-key-123456" }
      end

      it "returns a 200 response" do
        expect(response.status).to eq 200
        expect(JSON.parse(response.body).keys).to eq ["creneaux"]
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
end
