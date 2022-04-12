# frozen_string_literal: true

describe "Agent can see RDV details", js: true do
  before { travel_to(Time.zone.local(2022, 4, 4)) }

  describe "See RDV details" do
    let(:organisation) { create(:organisation) }
    let(:service) { create(:service) }
    let(:motif) { create(:motif, service: service, name: "Renseignements") }
    let!(:rdv) { create(:rdv, agents: [agent], motif: motif, organisation: organisation, starts_at: Time.zone.local(2022, 4, 7).at_noon) }
    let!(:receipt) { create(:receipt, rdv: rdv, result: :sent, sms_content: "Vous avez rendez-vous!") }
    let(:agent) { create(:agent, first_name: "Bruce", last_name: "Wayne", service: service, basic_role_in_organisations: [organisation]) }

    before do
      login_as(agent, scope: :agent)
      visit admin_organisation_rdvs_path(organisation)
    end

    it do
      expect(page).to have_text("Liste des RDV")
      click_link("Le jeudi 07 avril 2022")
      expect(page).to have_text("Renseignements")
      expect(page).to have_text("Bruce WAYNE")

      click_button("Notifications envoyées")
      expect(page).to have_text("Contenu")
      expect(page).to have_text("Vous avez rendez-vous!")
    end
  end
end
