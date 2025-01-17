require "swagger_helper"

RSpec.describe "Public links API", swagger_doc: "v1/api.json" do
  with_examples

  path "/api/v1/public_links" do
    get "Lister les liens publics de recherche" do
      tags "PublicLink"
      produces "application/json"
      operationId "getPublicLinks"
      description "Renvoie les liens publics de recherche d'un territoire donné"

      parameter name: "territory", in: :query, type: :string, description: "Le numéro ou code de département du territoire concerné", example: "26"

      response 200, "Retourne les liens publics de recherche" do
        let!(:terr) { create(:territory, departement_number: Territory::CN_DEPARTEMENT_NUMBER) }
        let!(:organisation_a) { create(:organisation, verticale: :rdv_aide_numerique, external_id: "ext_id_A", territory: terr) }
        let!(:organisation_b) { create(:organisation, verticale: :rdv_aide_numerique, external_id: "ext_id_B", territory: terr) }
        let!(:organisation_c) { create(:organisation, verticale: :rdv_aide_numerique, external_id: "ext_id_C", territory: terr) }
        let!(:organisation_d) { create(:organisation, verticale: :rdv_aide_numerique, external_id: "ext_id_D", territory: terr) }
        let!(:organisation_e) { create(:organisation, verticale: :rdv_aide_numerique, external_id: "ext_id_E", territory: terr) }
        let!(:organisation_f) { create(:organisation, verticale: :rdv_aide_numerique, external_id: "ext_id_F", territory: create(:territory)) }
        let!(:organisation_g) { create(:organisation, verticale: :rdv_aide_numerique, external_id: nil,        territory: terr) }

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
              {
                "external_id" => "ext_id_C",
                "public_link" => "http://www.rdv-aide-numerique-test.localhost/org/#{organisation_c.id}",
              },
            ],
          }
        end

        before do
          create(:plage_ouverture, organisation: organisation_a)
          create(:plage_ouverture, organisation: organisation_a)
          create(:plage_ouverture, :no_recurrence, organisation: organisation_b, first_day: Time.zone.today + 5.days)
          create(:plage_ouverture, :expired, organisation: organisation_d)
          create(:plage_ouverture, organisation: organisation_g)

          create(:rdv, :future, motif: create(:motif, :collectif), organisation: organisation_c)

          # Organisation A has two recurring plages
          # Organisation B has a plage in 5 days
          # Organisation B has an online reservable RDV collectif
          # Organisation D has a plage that expired
          # Organisation E has no plage
          # Organisation F is not in provided territory
          # Organisation G does not have an external ID
          # Organisation H does not exist
        end

        schema "$ref" => "#/components/schemas/public_links"

        run_test!

        it { expect(parsed_response_body).to match_array(expected_body) }
        # No ApiCall log for public links
        it { expect(ApiCall.count).to eq(0) }
      end

      response 400, "Retourne 'bad_request' quand le territory est manquant" do
        let(:territory) { nil }

        schema "$ref" => "#/components/schemas/error_missing"

        run_test!

        it { expect(parsed_response_body).to match(missing: "territory") }
      end

      it_behaves_like "an endpoint that returns 404 - not found", "le territory ne peut pas être trouvé" do
        let(:territory) { "unknown" }
      end

      it_behaves_like "an endpoint that returns 429 - too_many_requests", :get, Rails.application.routes.url_helpers.api_v1_public_links_path do
        let(:territory) { Territory::CN_DEPARTEMENT_NUMBER }
      end
    end
  end
end
