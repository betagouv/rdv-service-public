require "swagger_helper"

RSpec.describe "Motif Category Territory API" do
  path "/api/rdvinsertion/motif_category_territories/" do
    post "Activer une catégorie de motifs sur un territoire" do
      with_shared_secret_authentication

      tags "MotifCategoryTerritory"
      produces "application/json"
      operationId "createMotifCategoryTerritory"
      description "Activer une catégorie de motifs sur un territoire"

      parameter name: "organisation_id", in: :query, type: :integer, description: "ID de l'organisation", example: 12
      parameter name: "motif_category_short_name", in: :query, type: :string, description: "Nom de la catégorie (généralement parametrizé)", example: "rsa_orientation"

      let!(:agent) { create(:agent) }
      let!(:shared_secret) { "S3cr3T" }
      let!(:auth_headers) { api_auth_headers_with_shared_secret(agent, shared_secret) }
      let!(:uid) { auth_headers["uid"].to_s }
      let!(:"X-Agent-Auth-Signature") { auth_headers["X-Agent-Auth-Signature"].to_s }

      before do
        allow(Agent).to receive(:find_by).and_return(agent)
        allow(ENV).to receive(:fetch).with("SHARED_SECRET_FOR_AGENTS_AUTH").and_return(shared_secret)
        allow(ActiveSupport::SecurityUtils).to receive(:secure_compare).and_return(true)
      end

      response 200, "Active une catégorie de motifs sur un territoire" do
        let!(:territory) { create(:territory) }
        let!(:organisation) { create(:organisation, territory: territory) }
        let!(:organisation_id) { organisation.id }
        let!(:motif_category) { create(:motif_category) }
        let!(:motif_category_short_name) { motif_category.short_name }

        let!(:motif_categories_count_before) { territory.motif_categories.count }

        run_test!

        it { expect(territory.motif_categories.count).to eq(motif_categories_count_before + 1) }
        it { expect(territory.motif_categories.last.short_name).to eq(motif_category_short_name) }
        it { expect(parsed_response_body["territory"]["name"]).to match(territory.name) }
        it { expect(parsed_response_body["territory"]["motif_categories"][0]["short_name"]).to match(motif_category_short_name) }

        it "logs the API call" do
          expect(ApiCall.first.attributes.symbolize_keys).to include(
            controller_name: "motif_category_territories",
            action_name: "create",
            agent_id: agent.id
          )
        end
      end

      context "when authentication fails" do
        let!(:territory) { create(:territory) }
        let!(:organisation) { create(:organisation, territory: territory) }
        let!(:organisation_id) { organisation.id }
        let!(:motif_category) { create(:motif_category) }
        let!(:motif_category_short_name) { motif_category.short_name }

        before do
          allow(ActiveSupport::SecurityUtils).to receive(:secure_compare).and_return(false)
        end

        it "returns a 401 unauthorized response" do
          post "/api/rdvinsertion/motif_category_territories/", params: { organisation_id: organisation_id, motif_category_short_name: motif_category_short_name }, headers: auth_headers

          expect(response).to have_http_status(:unauthorized)
        end
      end
    end
  end
end
