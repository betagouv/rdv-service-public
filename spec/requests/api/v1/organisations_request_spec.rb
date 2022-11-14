# frozen_string_literal: true

require "swagger_helper"

describe "Organisations API", swagger_doc: "v1/api.json" do
  with_examples

  path "/api/v1/organisations" do
    get "Lister les organisations" do
      with_authentication
      with_pagination

      tags "Organisation"
      produces "application/json"
      operationId "getOrganisations"
      description "Renvoie toutes les organisations accessibles à l'agent·e authentifié·e, de manière paginée"

      parameter name: "departement_number", in: :query, type: :string, description: "Le numéro ou code de département du territoire concerné", example: "26", required: false
      parameter name: "city_code", in: :query, type: :string, description: "Le code INSEE de la localité", example: "26323", required: false

      let(:auth_headers) { api_auth_headers_for_agent(agent) }
      let(:"access-token") { auth_headers["access-token"].to_s }
      let(:uid) { auth_headers["uid"].to_s }
      let(:client) { auth_headers["client"].to_s }

      response 200, "Retourne des Organisations" do
        let!(:organisations) { create_list(:organisation, 5) }
        let!(:agent) { create(:agent, basic_role_in_organisations: Organisation.all) }
        let!(:other_organisation) { create(:organisation) }
        let!(:other_agent) { create(:agent, basic_role_in_organisations: [other_organisation]) }

        schema "$ref" => "#/components/schemas/organisations"

        run_test!

        it { expect(response).to be_paginated(current_page: 1, next_page: nil, prev_page: nil, total_count: 5, total_pages: 1) }

        it { expect(parsed_response_body[:organisations]).to match(OrganisationBlueprint.render_as_hash(organisations)) }
      end

      response 200, "Retourne des Organisations, filtrées par secteur géographique", document: false do
        let!(:unmatching) { create(:organisation) }
        let!(:matching) { create(:organisation) }
        let!(:agent) { create(:agent, basic_role_in_organisations: [unmatching, matching]) }
        let(:departement_number) { "26" }
        let(:city_code) { "26323" }

        before do
          allow(Users::GeoSearch).to receive(:new)
            .with(departement: departement_number, city_code: city_code, street_ban_id: nil)
            .and_return(instance_double(Users::GeoSearch, most_relevant_organisations: Organisation.where(id: matching.id)))
        end

        run_test!

        it { expect(parsed_response_body[:organisations]).to match([OrganisationBlueprint.render_as_hash(matching)]) }
      end

      response 200, "when there is no organisation", document: false do
        let(:agent) { create(:agent) }

        run_test!

        it { expect(parsed_response_body[:organisations]).to eq([]) }
      end

      it_behaves_like "an authenticated endpoint" do
        let(:agent) { create(:agent) }
      end
    end
  end
end
