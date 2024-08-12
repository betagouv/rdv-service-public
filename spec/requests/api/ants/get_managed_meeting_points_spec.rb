RSpec.describe "ANTS API: getManagedMeetingPoints" do
  include_context "rdv_mairie_api_authentication"

  context "with the wrong authentication header" do
    it "returns a 401 status" do
      get "/api/ants/getManagedMeetingPoints", headers: { "X-HUB-RDV-AUTH-TOKEN" => "wrong token" }
      expect(response.status).to eq 401
    end
  end

  context "with the correct authentication" do
    let!(:lieu1) do
      create(:lieu,
             organisation: organisation, name: "Mairie de Romainville",
             address: "89 rue Roger Bouvry, Seclin, 59113",
             longitude: 3.0348016639327,
             latitude: 50.549140395451)
    end
    let!(:lieu2) do
      create(:lieu,
             organisation: organisation, name: "Mairie de Paris 7",
             address: "89 rue du Général Leclerc, Paris, 75007",
             longitude: 4.0348016639327,
             latitude: 60.549140395451)
    end
    let(:organisation) { create(:organisation, territory: create(:territory, :mairies)) }

    it "returns a list of lieux" do
      get "/api/ants/getManagedMeetingPoints", headers: { "X-HUB-RDV-AUTH-TOKEN" => "" }
      expect(response.parsed_body).to contain_exactly({
          id: lieu1.id.to_s,
          name: "Mairie de Romainville",
          longitude: 3.0348016639327,
          latitude: 50.549140395451,
          public_entry_address: "89 rue Roger Bouvry",
          zip_code: "59113",
          city_name: "Seclin",
        }.stringify_keys, {
          id: lieu2.id.to_s,
          name: "Mairie de Paris 7",
          longitude: 4.0348016639327,
          latitude: 60.549140395451,
          public_entry_address: "89 rue du Général Leclerc",
          zip_code: "75007",
          city_name: "Paris",
        }.stringify_keys)
    end
  end
end
