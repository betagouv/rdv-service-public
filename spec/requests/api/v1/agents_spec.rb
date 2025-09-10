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
      post "/api/v1/agents", headers:, params:, as: :json

      expect(parsed_response_body["agent"]["email"]).to eq "francis@factice.fr"

      created_agent = Agent.find_by(email: "francis@factice.fr")

      expect(created_agent.roles.first).to have_attributes(
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
  end
end
