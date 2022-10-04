# frozen_string_literal: true

describe "api/v1/organisations/reservation_disponible requests", type: :request do
  let!(:territory) { create(:territory, departement_number: "CN") }
  let!(:organisation_a) { create(:organisation, new_domain_beta: true, external_id: "ext_id_A", territory: territory) }
  let!(:organisation_b) { create(:organisation, new_domain_beta: true, external_id: "ext_id_B", territory: territory) }
  let!(:organisation_c) { create(:organisation, new_domain_beta: true, external_id: "ext_id_C", territory: territory) }
  let!(:organisation_d) { create(:organisation, new_domain_beta: true, external_id: "ext_id_D", territory: territory) }
  let!(:organisation_e) { create(:organisation, new_domain_beta: true, external_id: "ext_id_E", territory: create(:territory)) }

  context "when plages are defined" do
    let(:params) do
      {
        external_ids: %w[ext_id_A ext_id_B ext_id_C ext_id_D ext_id_E],
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
      # Organisation E is not in provided territory, it should be missing from response
      # Organisation F does not exist, it should be missing from response
      expected_response = [
        {
          "organisation_external_id" => "ext_id_A",
          "reservation_disponible" => true,
          "public_url" => "http://www.rdv-aide-numerique-test.localhost/org/#{organisation_a.id}",
        },
        {
          "organisation_external_id" => "ext_id_B",
          "reservation_disponible" => true,
          "public_url" => "http://www.rdv-aide-numerique-test.localhost/org/#{organisation_b.id}",
        },
        {
          "organisation_external_id" => "ext_id_C",
          "reservation_disponible" => false,
          "public_url" => "http://www.rdv-aide-numerique-test.localhost/org/#{organisation_c.id}",
        },
        {
          "organisation_external_id" => "ext_id_D",
          "reservation_disponible" => false,
          "public_url" => "http://www.rdv-aide-numerique-test.localhost/org/#{organisation_d.id}",
        },
      ]
      expect(JSON.parse(response.body)).to match_array(expected_response)
    end
  end
end
