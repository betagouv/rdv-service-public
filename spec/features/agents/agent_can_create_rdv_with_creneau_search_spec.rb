# frozen_string_literal: true

describe "Agent can create a Rdv with creneau search" do
  include UsersHelper

  before do
    travel_to(now)
    login_as(agent, scope: :agent)
  end

  let!(:organisation) { create(:organisation) }
  let!(:lieu) { create(:lieu, organisation: organisation) }

  context "default" do
    let!(:organisation) { create(:organisation) }
    let!(:service) { create(:service) }
    let!(:agent) { create(:agent, first_name: "Alain", last_name: "Tiptop", service: service, basic_role_in_organisations: [organisation]) }
    let!(:agent2) { create(:agent, first_name: "Robert", last_name: "Voila", service: service, basic_role_in_organisations: [organisation]) }
    let!(:agent3) { create(:agent, first_name: "Michel", last_name: "Lapin", service: service, basic_role_in_organisations: [organisation]) }
    let!(:motif) { create(:motif, reservable_online: true, service: service, organisation: organisation) }
    let!(:user) { create(:user, organisations: [organisation]) }
    let!(:plage_ouverture) { create(:plage_ouverture, :daily, first_day: Date.new(2019, 7, 22), motifs: [motif], lieu: lieu, agent: agent, organisation: organisation) }
    let!(:lieu2) { create(:lieu, organisation: organisation) }
    let!(:plage_ouverture2) { create(:plage_ouverture, :daily, first_day: Date.new(2019, 7, 22), motifs: [motif], lieu: lieu2, agent: agent2, organisation: organisation) }
    let!(:plage_ouverture3) { create(:plage_ouverture, :daily, first_day: Date.new(2019, 7, 22), motifs: [motif], lieu: lieu, agent: agent3, organisation: organisation) }
    let(:now) { Time.zone.local(2019, 7, 22) }

    it "default", js: true do
      visit admin_organisation_agent_searches_path(organisation)
      expect(page).to have_content("Trouver un RDV")
      select(motif.name, from: "motif_id")
      click_button("Afficher les créneaux")

      # Display results for both lieux
      expect(page).to have_content(plage_ouverture.lieu.address)
      expect(page).to have_content(plage_ouverture2.lieu.address)

      # Add a filter on lieu
      select(lieu.name, from: "lieu_ids")
      click_button("Afficher les créneaux")
      expect(page).to have_content(plage_ouverture.lieu.address)
      expect(page).not_to have_content(plage_ouverture2.lieu.address)

      # TODO : refaire un parcours jusqu'à l'enregistrement du RDV
    end
  end

  context "when the motif is bookable online and the next creneau is after the max booking delay" do
    let!(:agent) { create(:agent, basic_role_in_organisations: [organisation]) }

    let!(:motif) { create(:motif, name: "Vaccination", organisation: organisation, max_booking_delay: 7.days, service: agent.service) }
    let!(:plage_ouverture) { create(:plage_ouverture, :daily, first_day: now + 8.days, motifs: [motif], lieu: lieu, organisation: organisation) }

    let(:now) { Time.zone.parse("2021-12-13 8:00") }

    it "still allows the agent to book a rdv, because the booking delays should only apply to agents", js: true do
      visit admin_organisation_agent_searches_path(organisation)
      expect(page).to have_content("Trouver un RDV")
      select(motif.name, from: "motif_id")
      click_button("Afficher les créneaux")

      # Display results
      expect(page).to have_content(plage_ouverture.lieu.address)
      expect(page).to have_content("Créneaux disponibles")
    end
  end
end
