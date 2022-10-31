# frozen_string_literal: true

require "swagger_helper"

describe "RDV authentified API", swagger_doc: "v1/api.json" do
  with_examples

  let!(:organisation) { create(:organisation) }
  let!(:organisation2) { create(:organisation) }

  let!(:service) { create(:service) }
  let!(:service2) { create(:service) }

  let!(:motif) { create(:motif, service: service) }
  let!(:motif2) { create(:motif, service: service2) }

  let!(:rdv) { create(:rdv, organisation: organisation, motif: motif) }
  let!(:rdv2) { create(:rdv, organisation: organisation2, motif: motif) }
  let!(:rdv3) { create(:rdv, organisation: organisation, motif: motif2) }

  let!(:basic_agent) do
    create(:agent, basic_role_in_organisations: [organisation], service: service)
  end
  let!(:admin_agent) do
    create(:agent, admin_role_in_organisations: [organisation], service: service)
  end

  path "/api/v1/organisations/{organisation_id}/rdvs" do
    get "Lister les rendez-vous d'une organisation" do
      with_authentication

      tags "RDV"
      produces "application/json"
      operationId "getRdvs"
      description "Renvoie les RDVs du service dont l'agent fait partie dans cette organisation. Si l'agent est administrateurice ou secrétaire, renvoie tous les RDVs de l'organisation en question."

      parameter name: :organisation_id, in: :path, type: :string, description: "Identifiant de l'organisation", example: "20"

      after do
        Rack::Attack.enabled = false
      end

      response 200, "Appel API réussi" do
        let(:organisation_id) { organisation.id }

        let(:access_basic_agent) { api_auth_headers_for_agent(basic_agent) }
        let(:"access-token") { access_basic_agent["access-token"].to_s }
        let(:uid) { access_basic_agent["uid"].to_s }
        let(:client) { access_basic_agent["client"].to_s }

        schema "$ref" => "#/components/schemas/rdvs"

        run_test!

        it "returns policy scoped RDVs" do
          expect(JSON.parse(response.body)["rdvs"].pluck("id")).to contain_exactly(rdv.id)
        end
      end

      response 200, "returns empty results when organisation is not found", document: false do
        let(:organisation_id) { "false" }

        let(:access_admin_agent) { api_auth_headers_for_agent(admin_agent) }
        let(:"access-token") { access_admin_agent["access-token"].to_s }
        let(:uid) { access_admin_agent["uid"].to_s }
        let(:client) { access_admin_agent["client"].to_s }

        run_test!

        it { expect(JSON.parse(response.body)["rdvs"]).to eq([]) }
      end

      response 200, "returns policy scoped RDVs when agent is admin", document: false do
        let(:organisation_id) { organisation.id }

        let(:access_admin_agent) { api_auth_headers_for_agent(admin_agent) }
        let(:"access-token") { access_admin_agent["access-token"].to_s }
        let(:uid) { access_admin_agent["uid"].to_s }
        let(:client) { access_admin_agent["client"].to_s }

        run_test!

        it { expect(JSON.parse(response.body)["rdvs"].pluck("id")).to contain_exactly(rdv.id, rdv3.id) }
      end

      response 401, "Problème d'authentification" do
        let(:access_admin_agent) { api_auth_headers_for_agent(admin_agent) }
        let(:"access-token") { "false" }
        let(:uid) { access_admin_agent["uid"].to_s }
        let(:client) { access_admin_agent["client"].to_s }
        let(:organisation_id) { organisation.id }

        schema "$ref" => "#/components/schemas/error_authentication"

        run_test!
      end

      response 429, "Limite d'appels atteinte" do
        let(:access_basic_agent) { api_auth_headers_for_agent(basic_agent) }
        let(:"access-token") { access_basic_agent["access-token"].to_s }
        let(:uid) { access_basic_agent["uid"].to_s }
        let(:client) { access_basic_agent["client"].to_s }
        let(:organisation_id) { organisation.id }

        schema "$ref" => "#/components/schemas/errors_generic"

        before do
          Rack::Attack.enabled = true
          Rack::Attack.reset!
          50.times do
            get api_v1_organisation_rdvs_path(organisation_id)
          end
        end

        run_test!
      end
    end
  end
end
