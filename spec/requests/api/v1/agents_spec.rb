RSpec.describe "Agents API" do
  let!(:oauth_token) { create(:access_token, resource_owner_id: agent.id, application:) }
  let(:headers) do
    { "Content-Type": "application/json", Authorization: "Bearer #{oauth_token.plaintext_token}" }
  end
  let(:application) { create(:oauth_application) }
  let(:agent) { create(:agent, admin_role_in_organisations: [organisation]) }
  let(:organisation) { create(:organisation) }

  describe "#create" do
    let(:params) do
      {
        email: "francis@factice.fr",
        organisation_ids: [organisation.id],
        access_level: "basic",
      }
    end

    it "invites the agent into the organisation" do
      expect do
        post "/api/v1/agents", headers:, params:, as: :json
      end.to change(Agent, :count).by(1)

      expect(parsed_response_body["agent"]["email"]).to eq "francis@factice.fr"

      created_agent = Agent.find_by(email: "francis@factice.fr")

      expect(created_agent.roles.sole).to have_attributes(
        access_level: "basic",
        organisation_id: organisation.id
      )
    end

    context "when the agent can't be created" do
      let(:params) do
        {
          email: "invalid",
          organisation_ids: [organisation.id],
          access_level: "basic",
        }
      end

      it "returns a error messages" do
        post "/api/v1/agents", headers:, params:, as: :json

        expect(response.status).to eq 422
        expect(parsed_response_body["error_messages"].first).to eq "Email n'est pas valide"
      end
    end

    context "l'agent invitant est admin d'une seule des orga auxquelles il invite un nouvel agent" do
      let(:agent) { create(:agent, :with_territory_access_rights, admin_role_in_organisations: [organisation]) }
      let!(:other_organisation) { create(:organisation, territory: organisation.territory) }

      it "bloque l'invitation" do
        expect do
          post "/api/v1/agents", headers:, params: {
            email: "autre@adresse.fr",
            organisation_ids: [organisation.id, other_organisation.id],
            access_level: "admin",
          }, as: :json
        end.not_to change(AgentRole, :count)
        expect(response).to have_http_status(:forbidden)
      end
    end
  end
end
