require "swagger_helper"

RSpec.describe "RDV authentified API", swagger_doc: "v1/api.json" do
  path "/api/v1/organisations/{organisation_id}/motifs" do
    get "Lister les motifs" do
      tags "Motif"
      produces "application/json"
      operationId "getMotifs"
      description "Renvoie tous les motifs à partir d'une organisation"

      with_authentication
      with_pagination

      parameter name: :organisation_id, in: :path, type: :integer, description: "Identifiant de l'organisation", example: "1"

      parameter name: :active, in: :query, type: :boolean, description: "filtre sur les motifs actifs", required: false
      parameter name: :bookable_publicly, in: :query, type: :boolean, description: "filtre sur les motifs réservables en ligne", required: false
      parameter name: :service_id, in: :query, type: :integer, description: "filtre sur les services", example: "1", required: false

      with_examples

      let!(:access_agent) { api_auth_headers_for_agent(agent) }
      let(:"access-token") { access_agent["access-token"].to_s }
      let(:uid) { access_agent["uid"].to_s }
      let(:client) { access_agent["client"].to_s }

      context "sans filtres" do
        response 200, "Renvoie les motifs", document: false do
          let!(:service) { create(:service) }
          let!(:organisation) { create(:organisation) }

          let!(:agent) { create(:agent, service: service, basic_role_in_organisations: [organisation]) }

          let!(:motif) { create(:motif, organisation: organisation, service: service) }

          let(:organisation_id) { organisation.id }

          run_test!

          it { expect(parsed_response_body[:motifs]).to eq(MotifBlueprint.render_as_json([motif])) }

          it "logs the API call" do
            expect(ApiCall.first.attributes.symbolize_keys).to include(
              controller_name: "motifs",
              action_name: "index",
              agent_id: agent.id
            )
          end
        end

        response 200, "Renvoie les motifs liés à la bonne organisation" do
          let!(:service) { create(:service) }
          let!(:organisation1) { create(:organisation) }
          let!(:organisation2) { create(:organisation) }

          let!(:agent) { create(:agent, service: service, basic_role_in_organisations: [organisation1]) }

          let!(:motif1) { create(:motif, organisation: organisation1, service: service) }
          let!(:motif2) { create(:motif, organisation: organisation1, service: service) }
          let!(:motif3) { create(:motif, organisation: organisation2, service: service) }

          let(:organisation_id) { organisation1.id }

          schema "$ref" => "#/components/schemas/motifs"

          run_test!

          it { expect(parsed_response_body[:motifs]).to eq(MotifBlueprint.render_as_json([motif1, motif2])) }
        end

        it_behaves_like "an endpoint that returns 401 - unauthorized" do
          let!(:agent) { create(:agent, service: service, basic_role_in_organisations: [organisation]) }
          let!(:service) { create(:service) }
          let!(:organisation) { create(:organisation) }
          let(:organisation_id) { organisation.id }
        end
      end

      context "avec filtres" do
        let!(:service) { create(:service) }
        let!(:organisation) { create(:organisation) }

        let!(:agent) { create(:agent, service: service, basic_role_in_organisations: [organisation]) }

        let(:organisation_id) { organisation.id }

        response 200, "Renvoie les motifs filtrés sur active true", document: false do
          let!(:deleted_at) { Time.zone.yesterday.noon }
          let!(:motif1) { create(:motif, organisation: organisation, service: service) }
          let!(:motif2) { create(:motif, organisation: organisation, service: service, deleted_at: deleted_at) }
          let(:active) { true }

          run_test!

          it { expect(parsed_response_body["motifs"].pluck("id")).to contain_exactly(motif1.id) }
        end

        response 200, "Renvoie les motifs filtrés sur active false", document: false do
          let!(:deleted_at) { Time.zone.yesterday.noon }
          let!(:motif1) { create(:motif, organisation: organisation, service: service) }
          let!(:motif2) { create(:motif, organisation: organisation, service: service, deleted_at: deleted_at) }
          let(:active) { false }

          run_test!

          it { expect(parsed_response_body["motifs"].pluck("id")).to contain_exactly(motif2.id) }
          it { expect(parsed_response_body["motifs"].pluck("deleted_at")).to contain_exactly(deleted_at.to_s) }
        end

        response 200, "Renvoie les motifs filtrés sur bookable_publicly true", document: false do
          let!(:motif1) { create(:motif, organisation: organisation, service: service, bookable_by: :everyone) }
          let!(:motif2) { create(:motif, organisation: organisation, service: service, bookable_by: :agents) }
          let!(:motif3) { create(:motif, organisation: organisation, service: service, bookable_by: :agents_and_prescripteurs_and_invited_users) }
          let(:bookable_publicly) { true }

          run_test!

          it { expect(parsed_response_body["motifs"].pluck("id")).to contain_exactly(motif1.id, motif3.id) }
        end

        response 200, "Renvoie les motifs filtrés sur bookable_publicly false", document: false do
          let!(:motif1) { create(:motif, organisation: organisation, service: service, bookable_by: :everyone) }
          let!(:motif2) { create(:motif, organisation: organisation, service: service, bookable_by: :agents) }
          let!(:motif3) { create(:motif, organisation: organisation, service: service, bookable_by: :agents_and_prescripteurs_and_invited_users) }
          let(:bookable_publicly) { false }

          run_test!

          it { expect(parsed_response_body["motifs"].pluck("id")).to contain_exactly(motif2.id) }
          it { expect(parsed_response_body["motifs"].pluck("bookable_publicly")).to contain_exactly(false) }
        end

        response 200, "Renvoie les motifs filtrés sur service_id", document: false do
          let!(:another_service) { create(:service) }
          let!(:motif1) { create(:motif, organisation: organisation, service: service) }
          let!(:motif2) { create(:motif, organisation: organisation, service: another_service) }
          let(:service_id) { service.id }

          run_test!

          it { expect(parsed_response_body["motifs"].pluck("id")).to contain_exactly(motif1.id) }
        end
      end
    end
  end
end
