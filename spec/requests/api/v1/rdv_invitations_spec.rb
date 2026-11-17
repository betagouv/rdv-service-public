RSpec.describe "RDV Invitations API" do
  let!(:oauth_token) do
    create(:access_token, resource_owner_id: agent.id, application:)
  end
  let(:headers) do
    {
      "Content-Type": "application/json",
      Authorization: "Bearer #{oauth_token.plaintext_token}",
    }
  end
  let(:application) { create(:oauth_application) }
  let(:agent) { create(:agent, admin_role_in_organisations: [organisation]) }
  let(:organisation) { create(:organisation) }

  describe "#index" do
    let(:motif) { create(:motif, organisation:) }
    let(:lieu) { create(:lieu, organisation:) }
    let(:user) { create(:user) }

    let!(:rdv_invitation) { create(:rdv_invitation, motif:, lieu:, user:, inviting_agent: agent) }
    let!(:other_user_rdv_invitation) { create(:rdv_invitation, motif:, inviting_agent: agent) }

    it "filters by user external_id" do
      create(:external_reference, item: user, oauth_application: application, external_id: "123AB")

      get "/api/v1/rdv_invitations", headers:, params: { user_external_id: "123AB" }, as: :json

      expect(parsed_response_body["rdv_invitations"].pluck("id")).to eq [rdv_invitation.id]
    end

    it "does not use the external_id given by another application" do
      create(:external_reference, item: user, oauth_application: create(:oauth_application), external_id: "123AB")

      get "/api/v1/rdv_invitations", headers:, params: { user_external_id: "123AB" }, as: :json

      expect(parsed_response_body["rdv_invitations"]).to be_empty
    end

    it "returns the motif, the lieu and the inviting agent" do
      get "/api/v1/rdv_invitations", headers:, as: :json

      expect(parsed_response_body["rdv_invitations"].find { _1["id"] == rdv_invitation.id }).to include(
        "inviting_agent" => include("id" => agent.id, "first_name" => agent.first_name, "last_name" => agent.last_name, "email" => agent.email),
        "motif" => include("id" => motif.id, "name" => motif.name, "location_type" => motif.location_type),
        "lieu" => include("id" => lieu.id, "name" => lieu.name, "address" => lieu.address)
      )
    end
  end
end
