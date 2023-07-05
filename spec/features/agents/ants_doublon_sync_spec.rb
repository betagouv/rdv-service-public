# frozen_string_literal: true

describe "Agent can update a RDV and changes are synced to the ANTS doublon api", js: true do
  let!(:organisation) { create(:organisation, verticale: :rdv_mairie) }
  let(:api_response1) do
    <<~JSON
          {
        "1234567890": {
          "status": "declared",
          "appointments": [
            {
              "management_url": "http://www.rdv-mairie-test.localhost/users/rdvs/#{rdv.id}",
              "meeting_point": "Mairie de Sannois",
              "appointment_date": "2023-07-04 09:00:00",
              "editor_comment": null
            }
          ]
        }

      }
    JSON
  end
  let(:api_response2) do
    <<~JSON
      { "1122334455": { "status": "unknown", "appointments": [] } }
    JSON
  end

  let!(:service) { create(:service) }
  let!(:agent) { create(:agent, first_name: "Alain", last_name: "Tiptop", service: service, basic_role_in_organisations: [organisation]) }
  let!(:user1) { create(:user, first_name: "Alex", last_name: "Test", ants_pre_demande_number: "1234567890", organisations: [organisation]) }
  let!(:user2) { create(:user, first_name: "Camille", last_name: "Test", ants_pre_demande_number: "1122334455", organisations: [organisation]) }
  let(:rdv) { create(:rdv, organisation: organisation, motif: motif, agents: [agent], lieu: lieu, users: [user1]) }
  let(:lieu) { create(:lieu, organisation: organisation, name: "Mairie de Sannois") }
  let(:motif) { create(:motif, service: service, organisation: organisation) }

  before do
    travel_to(Time.zone.parse("01-07-2023 09:00"))
    stub_netsize_ok
    login_as(agent, scope: :agent)
    GoodJob::Job.delete_all # delete the jobs for previous api sync
  end

  context "when removing a user and adding another one" do
    it "deletes an ants appointment and creates another one" do
      visit edit_admin_organisation_rdv_path(organisation, rdv)
      add_user(user2)
      find(:button, "Supprimer", match: :first).click
      click_button "Enregistrer"

      expect(page).to have_content("Le rendez-vous a été modifié.")

      stub_request(:get, "http://status/?application_ids=1234567890").to_return(status: 200, body: api_response1, headers: {})
      stub_request(:get, "http://status/?application_ids=1122334455").to_return(status: 200, body: api_response2, headers: {})

      expect(Typhoeus).to receive(:delete).with(
        "/appointments",
        {
          headers: { "Accept" => "application/json", "x-rdv-opt-auth-token" => nil },
          params: {
            application_id: "1234567890",
            appointment_date: "2023-07-04 09:00:00",
            meeting_point: "Mairie de Sannois",
          },

        }
      ).at_least(:once)
      expect(Typhoeus).to receive(:post).with(
        "/appointments",
        {

          headers: { "Accept" => "application/json", "x-rdv-opt-auth-token" => nil },
          params: {
            application_id: "1122334455",
            appointment_date: "2023-07-04 09:00:00",
            management_url: "http://www.rdv-mairie-test.localhost/users/rdvs/#{rdv.id}",
            meeting_point: "Mairie de Sannois",
          },
        }
      ).at_least(:once)

      perform_enqueued_jobs(queue: :default)
    end
  end
end
