# frozen_string_literal: true

require "swagger_helper"

describe "paginated requests", type: :request do
  let(:agent) { create(:agent) }
  let(:auth_headers) { api_auth_headers_for_agent(agent) }
  let(:"access-token") { auth_headers["access-token"].to_s }
  let(:uid) { auth_headers["uid"].to_s }
  let(:client) { auth_headers["client"].to_s }

  before do
    create_list(:agent_role, 210, agent: agent) # This also creates 210 new organisations
  end

  describe "default pagination" do
    path "/api/v1/organisations", document: false do
      get "La pagination fonctionne bien" do
        with_authentication
        with_pagination

        response 200, "Renvoie bien le meta de pagination" do
          let(:organisation_id) { organisation.id }

          schema "$ref" => "#/components/schemas/organisations"

          run_test!

          it { expect(parsed_response_body["organisations"].count).to eq(100) }
          it { expect(parsed_response_body["meta"]).to eq({ "current_page" => 1, "next_page" => 2, "prev_page" => nil, "total_count" => 210, "total_pages" => 3 }) }
        end
      end
    end
  end
end
