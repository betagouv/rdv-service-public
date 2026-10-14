require "swagger_helper"

RSpec.describe "paginated requests", swagger_doc: "v1/api.json", type: :request do
  let(:agent) { create(:agent) }

  before do
    stub_const("Api::V1::BaseController::PAGINATE_PER", 3)
    create_list(:agent_role, 7, agent: agent)
  end

  describe "default pagination" do
    path "/api/v1/organisations", document: false do
      get "La pagination fonctionne bien" do
        with_oauth_token_authentication
        with_pagination

        response 200, "Renvoie bien le meta de pagination" do
          let(:organisation_id) { organisation.id }

          schema "$ref" => "#/components/schemas/organisations"

          run_test!

          it { expect(parsed_response_body["organisations"].count).to eq(3) }

          it "is correctly paginated" do
            expect(response).to be_paginated(current_page: 1, next_page: 2, prev_page: nil, total_count: 7, total_pages: 3)
          end
        end
      end
    end
  end
end
