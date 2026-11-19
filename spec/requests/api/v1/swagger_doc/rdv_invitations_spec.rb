require "swagger_helper"

RSpec.describe "RDV authentified API", swagger_doc: "v1/api.json" do
  with_examples

  path "/api/v1/rdv_invitations" do
    get "Lister les invitations à prendre rendez-vous" do
      with_oauth_token_authentication
      with_pagination

      parameter name: :user_external_id, in: :query, type: :string,
                description: "Filtre pour obtenir uniquement les invitations de l'usager qui a cet id dans votre système.",
                example: "123AB", required: false

      tags "RDV Invitation"
      operationId "getRdvInvitations"
      description "Renvoie toutes les invitations à prendre rendez-vous accessibles à l'agent·e authentifié·e, de manière paginée"

      response 200, "Renvoie des invitations" do
        let!(:rdv_invitation) { create(:rdv_invitation, motif:, lieu: create(:lieu, organisation:), inviting_agent: agent) }
        let(:motif) { create(:motif, organisation:) }
        let!(:agent) { create(:agent, basic_role_in_organisations: [organisation]) }
        let!(:organisation) { create(:organisation) }

        schema({
                 type: "object",
                 properties: {
                   rdv_invitations: {
                     type: "array",
                     items: { type: "object" },
                   },
                   meta: { "$ref" => "#/components/schemas/meta" },
                 },
                 required: %w[rdv_invitations meta],
               })

        run_test!

        it { expect(parsed_response_body["rdv_invitations"].pluck("id")).to contain_exactly(rdv_invitation.id) }
      end
    end
  end
end
