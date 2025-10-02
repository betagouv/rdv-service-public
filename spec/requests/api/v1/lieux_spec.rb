RSpec.describe "Lieux API" do
  let!(:oauth_token) { create(:access_token, resource_owner_id: agent.id, application:) }
  let(:headers) do
    { "Content-Type": "application/json", Authorization: "Bearer #{oauth_token.plaintext_token}" }
  end
  let(:application) { create(:oauth_application, default_service: create(:service)) }

  let!(:organisation) { create(:organisation) }
  let!(:agent) { create(:agent, admin_role_in_organisations: [organisation]) }

  describe "#index" do
    let!(:lieu1) { create(:lieu, :enabled, organisation:, name: "MJD Nice") }
    let!(:lieu2) { create(:lieu, :enabled, organisation:, name: "TJ Menton") }
    let!(:lieu_ponctuel) { create(:lieu, :single_use, organisation:, name: "Place des Fêtes") }
    let!(:lieu_disabled) { create(:lieu, :disabled, organisation:, name: "Ancien Tribunal") }
    let!(:other_organisation) { create(:organisation) }
    let!(:lieu_other_org) { create(:lieu, :enabled, organisation: other_organisation, name: "CDAD Lille") }

    it "returns lieux from organizations the agent has access to" do
      get "/api/v1/lieux", headers: headers

      expect(response.status).to eq 200
      expect(parsed_response_body["lieux"]).to be_an(Array)
      expect(parsed_response_body["lieux"].length).to eq 3
      names = parsed_response_body["lieux"].pluck("name")
      expect(names).to include("MJD Nice", "TJ Menton", "Place des Fêtes")
      expect(names).not_to include("Ancien Tribunal") # disabled lieux are excluded by default
      expect(names).not_to include("CDAD Lille") # other organisation
    end

    it "filters by organisation_id when provided" do
      get "/api/v1/lieux", headers:, params: { organisation_id: organisation.id }

      expect(response.status).to eq 200
      expect(parsed_response_body["lieux"].length).to eq 3
      names = parsed_response_body["lieux"].pluck("name")
      expect(names).to include("MJD Nice", "TJ Menton", "Place des Fêtes")
      expect(names).not_to include("Ancien Tribunal", "CDAD Lille")
    end

    it "returns empty array when filtering by organisation_id agent doesn't have access to" do
      get "/api/v1/lieux", headers:, params: { organisation_id: other_organisation.id }

      expect(response.status).to eq 200
      expect(parsed_response_body["lieux"].length).to eq 0
    end

    it "returns disabled lieux when using the disabled filter" do
      get "/api/v1/lieux", headers:, params: { disabled: true }

      expect(response.status).to eq 200
      expect(parsed_response_body["lieux"].length).to eq 1
      names = parsed_response_body["lieux"].pluck("name")
      expect(names).to include("Ancien Tribunal")
      expect(names).not_to include("MJD Nice", "TJ Menton")
    end

    it "filters by type 'normal'" do
      get "/api/v1/lieux", headers:, params: { type: "normal" }

      expect(response.status).to eq 200
      expect(parsed_response_body["lieux"].length).to eq 2
      names = parsed_response_body["lieux"].pluck("name")
      expect(names).to include("MJD Nice", "TJ Menton")
      expect(names).not_to include("Place des Fêtes")
    end

    it "filters by type 'single_use'" do
      get "/api/v1/lieux", headers:, params: { type: "single_use" }

      expect(response.status).to eq 200
      expect(parsed_response_body["lieux"].length).to eq 1
      names = parsed_response_body["lieux"].pluck("name")
      expect(names).to include("Place des Fêtes")
      expect(names).not_to include("MJD Nice", "TJ Menton")
    end

    it "includes pagination metadata" do
      get "/api/v1/lieux", headers: headers

      expect(response.status).to eq 200
      expect(parsed_response_body["meta"]).to include(
        "current_page" => 1,
        "total_pages" => 1,
        "total_count" => 3
      )
    end

    context "when agent has no access to any organisation" do
      let!(:agent_no_access) { create(:agent) }
      let(:oauth_token) { create(:access_token, resource_owner_id: agent_no_access.id, application:) }

      it "returns empty array" do
        get "/api/v1/lieux", headers: headers

        expect(response.status).to eq 200
        expect(parsed_response_body["lieux"]).to be_empty
      end
    end
  end

  describe "#create" do
    context "without an external reference" do
      let(:params) do
        {
          organisation_id: organisation.id,
          latitude: 44.5569244,
          longitude: 4.7521632,
          name: "Maison France Service de Montreuil",
          address: "77 avenue de Ségur, 75015 Paris",
          phone_number: "01 22 33 44 55",
        }
      end

      it "creates the lieu" do
        expect { post "/api/v1/lieux", headers:, params:, as: :json }.to change(Lieu, :count)

        expect(response.status).to eq 200
        expect(parsed_response_body["name"]).to eq "Maison France Service de Montreuil"
      end
    end

    context "when a lieux already exists for the given external reference" do
      let(:params) do
        {
          organisation_id: organisation.id,
          latitude: 44.5569244,
          longitude: 4.7521632,
          name: "Maison France Service de Montreuil",
          address: "77 avenue de Ségur, 75015 Paris",
          phone_number: "01 22 33 44 55",
          external_reference: { external_id: "123ABC" },
        }
      end
      let!(:existing_lieu) do
        create(:lieu, organisation_id: organisation.id)
      end
      let!(:external_reference) do
        create(:external_reference, oauth_application: application, item: existing_lieu, territory_id: organisation.territory_id, external_id: "123ABC")
      end

      it "doesn't create the lieu and returns an error message" do
        expect { post "/api/v1/lieux", headers:, params:, as: :json }.not_to change(Lieu, :count)

        expect(response.status).to eq 422
        expect(parsed_response_body["error_messages"]).to eq ["external_id est déjà utilisé"]
      end
    end
  end
end
