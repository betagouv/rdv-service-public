RSpec.describe "ANTS API: searchApplicationIds" do
  include_context "rdv_mairie_api_authentication"

  context "with the wrong authentication header" do
    it "returns a 401 status" do
      get "/api/ants/searchApplicationIds", headers: { "X-HUB-RDV-AUTH-TOKEN" => "wrong token" }
      expect(response.status).to eq 401
    end
  end

  context "with the correct authentication" do
    it "returns a list of lieux" do
      get "/api/ants/searchApplicationIds?application_ids=1&application_ids=2", headers: { "X-HUB-RDV-AUTH-TOKEN" => "" }
      expect(response.parsed_body).to match({
                                                   "1" => [],
                                                   "2" => [],
                                                 })
    end
  end
end
