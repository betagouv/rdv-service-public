require "swagger_helper"

RSpec.describe "Motif Category API" do
  path "/api/rdvinsertion/motif_categories/" do
    post "Créer une catégorie de motifs" do
      with_shared_secret_authentication

      tags "MotifCategory"
      produces "application/json"
      operationId "createMotifCategory"
      description "Crée une catégorie de motifs"

      parameter name: "name", in: :query, type: :string, description: "Nom affiché de la catégorie de motifs", example: "RSA Orientation"
      parameter name: "short_name", in: :query, type: :string, description: "Nom de la catégorie (généralement parametrizé)", example: "rsa_orientation"

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

      response 200, "Crée une catégorie de motifs" do
        let(:name) { "RSA Orientation" }
        let(:short_name) { "rsa_orientation" }

        let!(:motif_categories_count_before) { MotifCategory.count }

        run_test!

        it { expect(MotifCategory.count).to eq(motif_categories_count_before + 1) }
        it { expect(MotifCategory.last.name).to eq(name) }
        it { expect(MotifCategory.last.short_name).to eq(short_name) }
        it { expect(parsed_response_body["motif_category"]["name"]).to match(name) }
        it { expect(parsed_response_body["motif_category"]["short_name"]).to match(short_name) }

        it "logs the API call" do
          expect(ApiCall.first.attributes.symbolize_keys).to include(
            controller_name: "motif_categories",
            action_name: "create",
            agent_id: agent.id
          )
        end
      end

      context "when authentication fails" do
        let(:name) { "RSA Orientation" }
        let(:short_name) { "rsa_orientation" }

        before do
          allow(ActiveSupport::SecurityUtils).to receive(:secure_compare).and_return(false)
        end

        it "returns a 401 unauthorized response" do
          post "/api/rdvinsertion/motif_categories/", params: { name: name, short_name: short_name }, headers: auth_headers

          expect(response).to have_http_status(:unauthorized)
        end
      end
    end
  end
end
