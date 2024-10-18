require "swagger_helper"

RSpec.describe "RDVs Users authentified API", swagger_doc: "v1/api.json" do
  with_examples

  path "api/v1/participations/{id}/" do
    patch "Mettre à jour une participation" do
      with_authentication

      tags "RDV"
      produces "application/json"
      operationId "putParticipations"
      description "Permet de modifier une participation à un rdv. Seul le champ `status` est modifiable."

      parameter name: :id, in: :path, type: :string, description: "Identifiant de la participation", example: "20"
      parameter(
        name: :participation,
        in: :query,
        schema: {
          type: :object,
          properties: {
            participation: {
              type: :object,
              properties: {
                status: { type: :string },
                enum: %w[unknown seen excused revoked noshow],
              },
              required: %w[status],
            },
          },
        },
        required: %w[participation]
      )

      response 200, "updates participation status", document: false do
        let!(:organisation) { create(:organisation) }
        let!(:service) { create(:service) }
        let!(:admin_agent) { create(:agent, admin_role_in_organisations: [organisation], service: service) }
        let(:access_admin_agent) { api_auth_headers_for_agent(admin_agent) }
        let(:"access-token") { access_admin_agent["access-token"].to_s }
        let(:uid) { access_admin_agent["uid"].to_s }
        let(:client) { access_admin_agent["client"].to_s }
        let(:user) { build(:user, first_name: "Jean") }
        let!(:participation_object) { create(:participation, status: "seen", user: user, rdv: rdv) }
        let!(:territorial_role) { AgentTerritorialRole.create(territory: organisation.territory, agent: admin_agent) }
        let!(:rdv) { create(:rdv, organisation: organisation, agents: [admin_agent]) }
        let(:participation) { { participation: { status: status } } }
        let(:id) { participation_object.id }
        let(:status) { "seen" }

        run_test!

        it do
          expect(response.parsed_body["rdv"]["status"]).to eq(status)
        end

        it "logs the API call" do
          expect(ApiCall.first.attributes.symbolize_keys).to include(
            controller_name: "participations",
            action_name: "update",
            agent_id: admin_agent.id
          )
        end
      end
    end
  end
end
