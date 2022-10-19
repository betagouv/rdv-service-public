# frozen_string_literal: true

describe "api/v1/public_links requests", type: :request do
  shared_examples "public links deliverer" do |path|
    let!(:territory) { create(:territory, departement_number: "CN") }
    let!(:organisation_a) { create(:organisation, new_domain_beta: true, external_id: "ext_id_A", territory: territory) }
    let!(:organisation_b) { create(:organisation, new_domain_beta: true, external_id: "ext_id_B", territory: territory) }
    let!(:organisation_c) { create(:organisation, new_domain_beta: true, external_id: "ext_id_C", territory: territory) }
    let!(:organisation_d) { create(:organisation, new_domain_beta: true, external_id: "ext_id_D", territory: territory) }
    let!(:organisation_e) { create(:organisation, new_domain_beta: true, external_id: "ext_id_E", territory: create(:territory)) }
    let!(:organisation_f) { create(:organisation, new_domain_beta: true, external_id: nil,        territory: territory) }

    it "returns any organisation that has any open plage ouverture" do
      create(:plage_ouverture, organisation: organisation_a)
      create(:plage_ouverture, organisation: organisation_a)
      create(:plage_ouverture, :no_recurrence, organisation: organisation_b, first_day: Time.zone.today + 5.days)
      create(:plage_ouverture, :expired, organisation: organisation_c)
      create(:plage_ouverture, organisation: organisation_f)

      get path, params: { territory: territory.departement_number }

      # Organisation A has two recurring plages
      # Organisation B has a plage in 5 days
      # Organisation C has a plage that expired
      # Organisation D has no plage
      # Organisation E is not in provided territory
      # Organisation F does not have an external ID
      # Organisation G does not exist
      expected_body = {
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
      expect(response).to have_http_status(:ok)
      expect(parsed_response_body).to match_array(expected_body)
    end

    it "returns a bad request error when the territory param is missing" do
      get path
      expect(response).to have_http_status(:bad_request)
      expect(parsed_response_body).to match(missing: "territory")
    end

    it "returns a not found error when the territory can't be found" do
      get path, params: { territory: "unknown" }
      expect(response).to have_http_status(:not_found)
      expect(parsed_response_body).to match(not_found: "territory")
    end
  end

  it_behaves_like "public links deliverer", "/api/v1/public_links"
  it_behaves_like "public links deliverer", "/public_api/public_links"
end
