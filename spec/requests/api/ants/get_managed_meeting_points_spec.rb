# frozen_string_literal: true

describe "ANTS API: getManagedMeetingPoints" do
  around do |example|
    previous_auth_token = ENV["ANTS_API_AUTH_TOKEN"]

    ENV["ANTS_API_AUTH_TOKEN"] = "fake_ants_api_auth_token"

    example.run

    ENV["ANTS_API_AUTH_TOKEN"] = previous_auth_token
  end

  context "with the wrong authentication header" do
    it "returns a 401 status" do
      get "/api/ants/getManagedMeetingPoints", headers: { "X-HUB-RDV-AUTH-TOKEN" => "wrong token" }
      expect(response.status).to eq 401
    end
  end

  context "with the correct authentication" do
    let!(:lieu) do
      create(:lieu,
             organisation: organisation, name: "Mairie de Romainville",
             address: "89 rue Roger Bouvry, Seclin, 59113",
             longitude: 3.0348016639327,
             latitude: 50.549140395451)
    end
    let(:organisation) { create(:organisation, verticale: :rdv_mairie) }

    it "returns a list of lieux" do
      get "/api/ants/getManagedMeetingPoints", headers: { "X-HUB-RDV-AUTH-TOKEN" => "fake_ants_api_auth_token" }
      expect(JSON.parse(response.body)).to eq [{
        id: lieu.id.to_s,
        name: "Mairie de Romainville",
        longitude: 3.0348016639327,
        latitude: 50.549140395451,
        public_entry_address: "89 rue Roger Bouvry",
        zip_code: "59113",
        city_name: "Seclin",
      }.stringify_keys]
    end
  end
end
