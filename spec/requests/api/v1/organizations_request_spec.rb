# frozen_string_literal: true

require "swagger_helper"

describe "Organization API", swagger_doc: "v1/api.json" do
  with_examples

  path "/api/v1/organizations" do
    get "Lister les organisations" do
      with_pagination

      tags "Organization"
      produces "application/json"
      operationId "getOrganizations"
      description "Renvoie toutes les organisations, de manière paginée"

      parameter name: :group_id, in: :query, type: :integer, description: "ID du Group sur lequel filtrer les organisations", example: "1", required: false

      response 200, "Retourne les Organisations sous la forme Organizations" do
        let!(:organizations) { create_list(:organisation, 5) }

        schema "$ref" => "#/components/schemas/organizations"

        run_test!

        it { expect(parsed_response_body[:meta]).to match(current_page: 1, next_page: nil, prev_page: nil, total_count: 5, total_pages: 1) }
        it { expect(parsed_response_body[:organizations]).to match(OrganizationBlueprint.render_as_hash(organizations)) }
      end

      response 200, "Filtre par rapport à un territoire", document: false do
        let!(:matching) { create(:organisation) }
        let!(:unmatching) { create(:organisation) }
        let!(:group_id) { matching.territory_id }

        run_test!

        it { expect(parsed_response_body[:organizations]).to include(OrganizationBlueprint.render_as_hash(matching)) }
        it { expect(parsed_response_body[:organizations]).not_to include(OrganizationBlueprint.render_as_hash(unmatching)) }
      end

      response 200, "Renvoie une liste vide s'il n'y a pas d'organisations", document: false do
        run_test!

        it { expect(parsed_response_body[:organizations]).to match([]) }
      end

      response 429, "Limite d'appels atteinte" do
        schema "$ref" => "#/components/schemas/error_too_many_request"

        before do
          Rack::Attack.enabled = true
          Rack::Attack.reset!
          50.times do
            get api_v1_organizations_path
          end
        end

        run_test!
      end
    end
  end
end
