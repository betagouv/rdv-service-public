# frozen_string_literal: true

require "swagger_helper"

describe "RDVs Users authentified API", swagger_doc: "v1/api.json" do
  with_examples

  path "api/v1/rdvs_users/{id}/" do
    put "Mettre à jour une participation" do
      with_authentication

      tags "RDV"
      produces "application/json"
      operationId "putRdvsUsers"
      description "Permet de modifier une participation à un rdv. Seul le champ `status` est modifiable."

      parameter name: :id, in: :path, type: :string, description: "Identifiant de la participation", example: "20"
      parameter(
        name: :rdvs_user,
        in: :query,
        schema: {
          type: :object,
          properties: {
            rdvs_user: {
              type: :object,
              properties: {
                status: { type: :string },
                enum: %w[unknown seen excused revoked noshow],
              },
              required: %w[status],
            },
          },
        },
        required: %w[rdvs_user]
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
        let!(:participation) { create(:rdvs_user, status: "seen", user: user, rdv: rdv) }
        let!(:territorial_role) { AgentTerritorialRole.create(territory: organisation.territory, agent: admin_agent) }
        let!(:rdv) { create(:rdv, organisation: organisation, agents: [admin_agent]) }
        let(:id) { participation.id }
        let(:status) { "seen" }
        let(:rdvs_user) { { rdvs_user: { status: status } } }

        run_test!

        it do
          expect(response.parsed_body["rdv"]["status"]).to eq(status)
        end
      end
    end
  end
end
