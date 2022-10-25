# frozen_string_literal: true

require "swagger_helper"

describe "Public links API", swagger_doc: "v1/api.json" do
  path "/api/v1/public_links" do
    get "Lister les liens publics de recherche" do
      tags "PublicLink"
      produces "application/json"
      operationId "getPublicLinks"
      description "Renvoie les liens publics de recherche d'un territoire donné"

      parameter name: "territory", in: :query, type: :string, description: "Le numéro ou code de département du territoire concerné", example: "26"

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

      response 200, "Retourne les liens publics de recherche" do
        let!(:terr) { create(:territory, departement_number: "CN") }
        let!(:organisation_a) { create(:organisation, new_domain_beta: true, external_id: "ext_id_A", territory: terr) }
        let!(:organisation_b) { create(:organisation, new_domain_beta: true, external_id: "ext_id_B", territory: terr) }
        let!(:organisation_c) { create(:organisation, new_domain_beta: true, external_id: "ext_id_C", territory: terr) }
        let!(:organisation_d) { create(:organisation, new_domain_beta: true, external_id: "ext_id_D", territory: terr) }
        let!(:organisation_e) { create(:organisation, new_domain_beta: true, external_id: "ext_id_E", territory: create(:territory)) }
        let!(:organisation_f) { create(:organisation, new_domain_beta: true, external_id: nil,        territory: terr) }

        let(:territory) { terr.departement_number }

        let(:expected_body) do
          {
            "public_links" => [
              {
                "external_id" => "ext_id_A",
                "public_link" => "http://www.rdv-aide-numerique-test.localhost/org/#{organisation_a.id}",
              },
              {
                "external_id" => "ext_id_B",
                "public_link" => "http://www.rdv-aide-numerique-test.localhost/org/#{organisation_b.id}",
              },
            ],
          }
        end

        before do
          create(:plage_ouverture, organisation: organisation_a)
          create(:plage_ouverture, organisation: organisation_a)
          create(:plage_ouverture, :no_recurrence, organisation: organisation_b, first_day: Time.zone.today + 5.days)
          create(:plage_ouverture, :expired, organisation: organisation_c)
          create(:plage_ouverture, organisation: organisation_f)

          # Organisation A has two recurring plages
          # Organisation B has a plage in 5 days
          # Organisation C has a plage that expired
          # Organisation D has no plage
          # Organisation E is not in provided territory
          # Organisation F does not have an external ID
          # Organisation G does not exist
        end

        run_test!

        it { expect(response).to have_http_status(:ok) }

        it { expect(parsed_response_body).to match_array(expected_body) }
      end

      response 400, "Retourne 'bad_request' quand le territory est manquant" do
        let(:territory) { nil }

        run_test!

        it { expect(response).to have_http_status(:bad_request) }
        it { expect(parsed_response_body).to match(missing: "territory") }
      end

      response 404, "Retourne 'not_found' quand le territory ne peut pas être trouvé" do
        let(:territory) { "unknown" }

        run_test!

        it { expect(response).to have_http_status(:not_found) }

        it { expect(parsed_response_body).to match(not_found: "territory") }
      end
    end
  end
end
