# frozen_string_literal: true

describe "public_api/public_links requests", type: :request do
  let!(:territory) { create(:territory, departement_number: "CN") }
  let!(:organisation_a) { create(:organisation, new_domain_beta: true, external_id: "ext_id_A", territory: territory) }
  let!(:organisation_b) { create(:organisation, new_domain_beta: true, external_id: "ext_id_B", territory: territory) }
  let!(:organisation_c) { create(:organisation, new_domain_beta: true, external_id: "ext_id_C", territory: territory) }
  let!(:organisation_d) { create(:organisation, new_domain_beta: true, external_id: "ext_id_D", territory: territory) }
  let!(:organisation_e) { create(:organisation, new_domain_beta: true, external_id: "ext_id_E", territory: create(:territory)) }

  context "when plages are defined" do
    let(:params) do
      {
        external_ids: %w[ext_id_A ext_id_B ext_id_C ext_id_D ext_id_E, ext_id_F],
        departement: "CN",
      }
    end

    it "returns the list of organisations" do
      create(:plage_ouverture, organisation: organisation_a)
      create(:plage_ouverture, :no_recurrence, organisation: organisation_b, first_day: Time.zone.today + 5.days)
      create(:plage_ouverture, :expired, organisation: organisation_c)

      get "/public_api/public_links", params: params, headers: {}

      # Organisation A has a normal recurring plage
      # Organisation B has a plage in 5 days
      # Organisation C has a plage that expired
      # Organisation D has no plage
      # Organisation E is not in provided territory
      # Organisation F does not exist
      expected_response = {
        "ext_id_A" => "http://www.rdv-aide-numerique-test.localhost/org/#{organisation_a.id}",
        "ext_id_B" => "http://www.rdv-aide-numerique-test.localhost/org/#{organisation_b.id}",
      }
      expect(JSON.parse(response.body)).to match_array(expected_response)
    end
  end
end
