# frozen_string_literal: true

require "swagger_helper"

describe "Organization API", swagger_doc: "v1/api.json" do
  path "/api/v1/organizations" do
    get "Lister les organisations" do
      tags "Organization"
      produces "application/json"
      operationId "getOrganizations"
      description "Renvoie toutes les organisations de manière paginée"

      parameter name: "page", in: :query, type: :integer, description: "La page souhaitée", example: "1", required: false
      parameter name: "per", in: :query, type: :integer, description: "Le nombre d'éléments souhaités par page", example: "10", required: false
      parameter name: :group_id, in: :query, type: :integer, description: "ID du Group sur lequel filtrer les organisations", example: "1", required: false

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

      response 200, "Retourne les Organisations sous la forme Organizations" do
        let!(:page1) { create_list(:organisation, 2) }
        let!(:page2) { create_list(:organisation, 2) }
        let!(:page3) { create_list(:organisation, 1) }

        let(:page) { 2 }
        let(:per) { 2 }

        schema "$ref" => "#/components/schemas/organizations"

        run_test!

        it { expect(parsed_response_body[:meta]).to match(current_page: 2, next_page: 3, prev_page: 1, total_count: 5, total_pages: 3) }
        it { expect(parsed_response_body[:organizations]).to match(OrganizationBlueprint.render_as_hash(page2)) }
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
    end
  end
end
