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
        let!(:groups) { create_list(:territory, 5) }

        schema "$ref" => "#/components/schemas/groups"

        run_test!

        it { expect(parsed_response_body[:meta]).to match(current_page: 1, next_page: nil, prev_page: nil, total_count: 5, total_pages: 1) }

        it { expect(parsed_response_body[:groups]).to match(GroupBlueprint.render_as_hash(groups)) }
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
