# frozen_string_literal: true

require "swagger_helper"

describe "Groups API", swagger_doc: "v1/api.json" do
  path "/api/v1/groups" do
    get "Lister les groupes (représentation des territoires)" do
      tags "Group"
      produces "application/json"
      operationId "getGroups"
      description "Renvoie tous les groupes, qui représentent les territoires, de manière paginée."

      parameter name: "page", in: :query, type: :integer, description: "La page souhaitée", example: "1", required: false
      parameter name: "per", in: :query, type: :integer, description: "Le nombre d'éléments souhaités par page", example: "10", required: false

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

      response(200, "Appel API réussi") do
        schema "$ref" => "#/components/schemas/get_groups"

        context "when there is at least one territory" do
          before { create(:territory) }

          run_test!

          it { expect(response).to have_http_status(:ok) }

          it { expect(parsed_response_body[:groups]).to match(GroupBlueprint.render_as_hash(Territory.all)) }
        end

        context "when there is no territory" do
          run_test!

          it { expect(response).to have_http_status(:ok) }

          it { expect(parsed_response_body[:groups]).to match([]) }
        end

        context "when there is a lot of territories" do
          let!(:page1) { create_list(:territory, 2) }
          let!(:page2) { create_list(:territory, 2) }
          let!(:page3) { create_list(:territory, 1) }

          let(:page) { 2 }
          let(:per) { 2 }

          run_test!

          it { expect(parsed_response_body[:meta]).to match(current_page: 2, next_page: 3, prev_page: 1, total_count: 5, total_pages: 3) }

          it { expect(parsed_response_body[:groups]).to match(GroupBlueprint.render_as_hash(page2)) }
        end
      end
    end
  end
end
