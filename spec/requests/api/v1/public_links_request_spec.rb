# frozen_string_literal: true

require "swagger_helper"

describe "Public links API", swagger_doc: "v1/api.json" do
  with_examples

  path "/api/v1/public_links" do
    get "Lister les liens publics de recherche" do
      tags "PublicLink"
      produces "application/json"
      operationId "getPublicLinks"
      description "Renvoie les liens publics de recherche d'un territoire donné"

      parameter name: "territory", in: :query, type: :string, description: "Le numéro ou code de département du territoire concerné", example: "26"

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

        schema "$ref" => "#/components/schemas/public_links"

        run_test!

        it { expect(parsed_response_body).to match_array(expected_body) }
      end

      response 400, "Retourne 'bad_request' quand le territory est manquant" do
        let(:territory) { nil }

        schema "$ref" => "#/components/schemas/error_missing"

        run_test!

        it { expect(parsed_response_body).to match(missing: "territory") }
      end

      it_behaves_like "an endpoint that looks for a resource", "le territory ne peut pas être trouvé" do
        let(:territory) { "unknown" }
      end

      it_behaves_like "a rate limited endpoint", :get, Rails.application.routes.url_helpers.api_v1_public_links_path do
        let(:territory) { "CN" }
      end
    end
  end
end
