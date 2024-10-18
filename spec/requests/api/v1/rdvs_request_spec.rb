require "swagger_helper"

RSpec.describe "RDV authentified API", swagger_doc: "v1/api.json" do
  with_examples

  path "/api/v1/organisations/{organisation_id}/rdvs" do
    get "Lister les rendez-vous d'une organisation" do
      with_authentication

      tags "RDV"
      produces "application/json"
      operationId "getRdvs"
      description "Renvoie les RDVs du service dont l'agent fait partie dans cette organisation. Si l'agent est administrateurice ou secrétaire, renvoie tous les RDVs de l'organisation en question."

      parameter name: :organisation_id, in: :path, type: :string, description: "Identifiant de l'organisation", example: "20"

      parameter name: :starts_after, in: :query, type: :string,
                description: "Filtre les rendez-vous avec un starts_at aprés cette date. Accepte des formats date ou time (iso8601).",
                example: "2020-01-01", required: false
      parameter name: :starts_before, in: :query, type: :string,
                description: "Filtre les rendez-vous avec un starts_at avant cette date. Accepte des formats date ou time (iso8601).",
                example: "2020-01-01", required: false

      let(:access_basic_agent) { api_auth_headers_for_agent(basic_agent) }
      let(:"access-token") { access_basic_agent["access-token"].to_s }
      let(:uid) { access_basic_agent["uid"].to_s }
      let(:client) { access_basic_agent["client"].to_s }

      let!(:organisation) { create(:organisation) }
      let!(:organisation2) { create(:organisation) }

      let!(:service) { create(:service) }
      let!(:service2) { create(:service) }

      let!(:motif) { create(:motif, service: service) }
      let!(:motif2) { create(:motif, service: service2) }

      let!(:rdv) { create(:rdv, organisation: organisation, motif: motif, starts_at: "2022-01-01 09:00:00 +0200") }
      let!(:rdv2) { create(:rdv, organisation: organisation2, motif: motif, starts_at: "2023-01-01 09:00:00 +0200") }
      let!(:rdv3) { create(:rdv, organisation: organisation, motif: motif2, starts_at: "2024-01-01 09:00:00 +0200") }

      let!(:basic_agent) { create(:agent, basic_role_in_organisations: [organisation], service: service) }
      let(:organisation_id) { organisation.id }

      after do
        Rack::Attack.enabled = false
      end

      response 200, "Appel API réussi" do
        schema "$ref" => "#/components/schemas/rdvs"

        run_test!

        it "returns policy scoped RDVs" do
          expect(response.parsed_body["rdvs"].pluck("id")).to contain_exactly(rdv.id)
          expect(response.parsed_body["rdvs"].pluck("created_by")).to contain_exactly("agent")
        end
      end

      response 200, "returns empty results when organisation is not found", document: false do
        let(:organisation_id) { "false" }

        run_test!

        it { expect(response.parsed_body["rdvs"]).to eq([]) }

        it "logs the API call" do
          expect(ApiCall.first.attributes.symbolize_keys).to include(
            controller_name: "rdvs",
            action_name: "index",
            agent_id: basic_agent.id
          )
        end
      end

      context "with starts_after and starts_before params" do
        let!(:rdv2020) { create(:rdv, organisation: organisation, motif: motif, starts_at: "2020-01-01 09:00:00 +0200") }
        let!(:rdv2021) { create(:rdv, organisation: organisation, motif: motif, starts_at: "2021-01-01 09:00:00 +0200") }

        response 200, "returns policy scoped RDVs filtered with starts_after and starts_before", document: false do
          let(:starts_after) { "2020-01-01" }
          let(:starts_before) { "2020-01-02" }

          run_test!

          it { expect(response.parsed_body["rdvs"].pluck("id")).to contain_exactly(rdv2020.id) }
        end

        response 200, "returns policy scoped RDVs filtered with starts_after only", document: false do
          let(:starts_after) { "2020-01-01" }

          run_test!

          it { expect(response.parsed_body["rdvs"].pluck("id")).to contain_exactly(rdv2020.id, rdv2021.id, rdv.id) }
        end

        response 200, "returns policy scoped RDVs filtered with starts_before only", document: false do
          let(:starts_before) { "2020-01-02" }

          run_test!

          it { expect(response.parsed_body["rdvs"].pluck("id")).to contain_exactly(rdv2020.id) }
        end

        response 200, "also works with time params", document: false do
          let(:starts_before) { "2020-01-01 10:00:00" }

          run_test!

          it { expect(response.parsed_body["rdvs"].pluck("id")).to contain_exactly(rdv2020.id) }
        end

        response 200, "also works with time params (with another standard)", document: false do
          let(:starts_before) { "2020-01-01T01:00:00+02:00" }

          run_test!

          it { expect(response.parsed_body["rdvs"].pluck("id")).to be_empty }
        end
      end

      response 200, "returns policy scoped RDVs when agent is admin", document: false do
        let!(:admin_agent) { create(:agent, admin_role_in_organisations: [organisation], service: service) }
        let(:access_admin_agent) { api_auth_headers_for_agent(admin_agent) }
        let(:"access-token") { access_admin_agent["access-token"].to_s }
        let(:uid) { access_admin_agent["uid"].to_s }
        let(:client) { access_admin_agent["client"].to_s }

        run_test!

        it { expect(response.parsed_body["rdvs"].pluck("id")).to contain_exactly(rdv.id, rdv3.id) }
      end

      it_behaves_like "an endpoint that returns 401 - unauthorized"
    end
  end
end
