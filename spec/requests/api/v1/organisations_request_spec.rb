# frozen_string_literal: true

require "swagger_helper"

describe "Organisations API", swagger_doc: "v1/api.json" do
  path "/api/v1/organisations" do
    get "Lister les organisations" do
      tags "Organisation"
      produces "application/json"
      operationId "getOrganisations"
      description "Renvoie toutes les organisations accessibles à l'agent·e authentifié·e, de manière paginée."

      security [{ access_token: [], uid: [], client: [] }]

      parameter name: "access-token", in: :header, type: :string, description: "Token d'accès (authentification)", example: "SFYBngO55ImjD1HOcv-ivQ"
      parameter name: "client", in: :header, type: :string, description: "Clé client d'accès (authentification)", example: "Z6EihQAY9NWsZByfZ47i_Q"
      parameter name: "uid", in: :header, type: :string, description: "Identifiant d'accès (authentification)", example: "martine@demo.rdv-solidarites.fr"

      parameter name: "page", in: :query, type: :integer, description: "La page souhaitée", example: "1", required: false
      parameter name: "per", in: :query, type: :integer, description: "Le nombre d'éléments souhaités par page", example: "10", required: false

      parameter name: "departement_number", in: :query, type: :integer, description: "Le numéro de département", example: "26", required: false
      parameter name: "city_code", in: :query, type: :integer, description: "Le code INSEE de la localité", example: "26323", required: false

      after do |example|
        content = example.metadata[:response][:content] || {}
        example_spec = {
          "application/json" => {
            examples: {
              example: {
                value: JSON.parse(response.body, symbolize_names: true),
              },
            },
          },
        }
        example.metadata[:response][:content] = content.deep_merge(example_spec)
      end

      response 200, "Retourne des Organisations" do
        let!(:page1) { create_list(:organisation, 2) }
        let!(:page2) { create_list(:organisation, 2) }
        let!(:page3) { create_list(:organisation, 1) }
        let!(:agent) { create(:agent, basic_role_in_organisations: Organisation.all) }
        let!(:other_organisation) { create(:organisation) }
        let!(:other_agent) { create(:agent, basic_role_in_organisations: [other_organisation]) }

        let(:auth_headers) { api_auth_headers_for_agent(agent) }
        let(:"access-token") { auth_headers["access-token"].to_s }
        let(:uid) { auth_headers["uid"].to_s }
        let(:client) { auth_headers["client"].to_s }

        let(:page) { 2 }
        let(:per) { 2 }

        run_test!

        it { expect(response).to have_http_status(:ok) }

        it { expect(parsed_response_body[:meta]).to match(current_page: 2, next_page: 3, prev_page: 1, total_count: 5, total_pages: 3) }

        it { expect(parsed_response_body[:organisations]).to match(OrganisationBlueprint.render_as_hash(page2)) }
      end

      response 200, "Retourne des Organisations, filtrées par secteur géographique", document: false do
        let!(:unmatching) { create(:organisation) }
        let!(:matching) { create(:organisation) }
        let!(:agent) { create(:agent, basic_role_in_organisations: [unmatching, matching]) }
        let(:departement_number) { "26" }
        let(:city_code) { "26323" }

        let(:auth_headers) { api_auth_headers_for_agent(agent) }
        let(:"access-token") { auth_headers["access-token"].to_s }
        let(:uid) { auth_headers["uid"].to_s }
        let(:client) { auth_headers["client"].to_s }

        before do
          allow(Users::GeoSearch).to receive(:new)
            .with(departement: departement_number, city_code: city_code, street_ban_id: nil)
            .and_return(instance_double(Users::GeoSearch, most_relevant_organisations: Organisation.where(id: matching.id)))
        end

        run_test!

        it { expect(response).to have_http_status(:ok) }

        it { expect(parsed_response_body[:organisations]).to match([OrganisationBlueprint.render_as_hash(matching)]) }
      end

      response 200, "when there is no organisation", document: false do
        let(:agent) { create(:agent) }
        let(:auth_headers) { api_auth_headers_for_agent(agent) }
        let(:"access-token") { auth_headers["access-token"].to_s }
        let(:uid) { auth_headers["uid"].to_s }
        let(:client) { auth_headers["client"].to_s }

        run_test!

        it { expect(response).to have_http_status(:ok) }

        it { expect(parsed_response_body[:organisations]).to eq([]) }
      end

      response 401, "Problème d'authentification" do
        let(:agent) { create(:agent) }
        let(:auth_headers) { api_auth_headers_for_agent(agent) }
        let(:"access-token") { "false" }
        let(:uid) { auth_headers["uid"].to_s }
        let(:client) { auth_headers["client"].to_s }

        schema "$ref" => "#/components/schemas/errors_object"

        run_test!
      end
    end
  end
end
