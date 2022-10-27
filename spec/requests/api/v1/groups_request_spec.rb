# frozen_string_literal: true

require "swagger_helper"

describe "Groups API", swagger_doc: "v1/api.json" do
  with_examples

  path "/api/v1/groups" do
    get "Lister les groupes (représentation des territoires)" do
      with_pagination

      tags "Group"
      produces "application/json"
      operationId "getGroups"
      description "Renvoie tous les groupes, qui représentent les territoires, de manière paginée"

      response 200, "Retourne des Groups" do
        let!(:page1) { create_list(:territory, 2) }
        let!(:page2) { create_list(:territory, 2) }
        let!(:page3) { create_list(:territory, 1) }

        let(:page) { 2 }
        let(:per) { 2 }

        schema "$ref" => "#/components/schemas/groups"

        run_test!

        it { expect(parsed_response_body[:meta]).to match(current_page: 2, next_page: 3, prev_page: 1, total_count: 5, total_pages: 3) }

        it { expect(parsed_response_body[:groups]).to match(GroupBlueprint.render_as_hash(page2)) }
      end

      response 200, "when there is at least one territory", document: false do
        before { create(:territory) }

        run_test!

        it { expect(parsed_response_body[:groups]).to match(GroupBlueprint.render_as_hash(Territory.all)) }
      end

      response 200, "when there is no territory", document: false do
        run_test!

        it { expect(parsed_response_body[:groups]).to match([]) }
      end
    end
  end
end
