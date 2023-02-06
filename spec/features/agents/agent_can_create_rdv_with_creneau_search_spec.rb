# frozen_string_literal: true

describe "Agent can create a Rdv with creneau search" do
  include UsersHelper

  before { login_as(agent, scope: :agent) }

  let!(:organisation) { create(:organisation) }
  let!(:agent) { create(:agent, basic_role_in_organisations: [organisation]) }

  context "when there are multiple plage d'ouverture and lieux" do
    let!(:motif) { create(:motif, bookable_publicly: true, service: agent.service, organisation: organisation) }
    let!(:plage_ouverture) { create(:plage_ouverture, :daily, motifs: [motif], agent: agent, organisation: organisation) }
    let!(:plage_ouverture2) { create(:plage_ouverture, :daily, motifs: [motif], organisation: organisation) }

    it "displays lieux and allow filtering on lieux", js: true do
      visit admin_organisation_agent_searches_path(organisation)
      expect(page).to have_content("Trouver un RDV")
      select(motif.name, from: "motif_id")
      click_button("Afficher les créneaux")

      # Display results for both lieux
      expect(page).to have_content(plage_ouverture.lieu_address)
      expect(page).to have_content(plage_ouverture2.lieu_address)

      # Add a filter on lieu
      select(plage_ouverture.lieu_name, from: "lieu_ids")
      click_button("Afficher les créneaux")
      expect(page).to have_content(plage_ouverture.lieu_address)
      expect(page).not_to have_content(plage_ouverture2.lieu_address)

      # TODO : refaire un parcours jusqu'à l'enregistrement du RDV
    end
  end

  context "when the motif is bookable online and the next creneau is after the max booking delay" do
    let!(:motif) { create(:motif, name: "Vaccination", organisation: organisation, max_public_booking_delay: 7.days, service: agent.service) }
    let!(:plage_ouverture) { create(:plage_ouverture, :daily, first_day: 8.days.since, motifs: [motif], organisation: organisation) }

    it "still allows the agent to book a rdv, because the booking delays should only apply to agents", js: true do
      visit admin_organisation_agent_searches_path(organisation)
      expect(page).to have_content("Trouver un RDV")
      select(motif.name, from: "motif_id")
      click_button("Afficher les créneaux")

      # Display results
      expect(page).to have_content(plage_ouverture.lieu_address)
      expect(page).to have_content("Créneaux disponibles")
    end
  end

  context "when the motif doesn't require a lieu" do
    let!(:plage_ouverture) { create(:plage_ouverture, :daily, first_day: Time.zone.today, motifs: [motif], agent: agent, organisation: organisation) }
    let!(:plage_ouverture_without_lieu) { create(:plage_ouverture, motifs: [motif], lieu: nil, organisation: organisation) }

    shared_examples "book a rdv without a lieu" do
      it "allows the agent to book a rdv", js: true do
        visit admin_organisation_agent_searches_path(organisation)
        expect(page).to have_content("Trouver un RDV")
        select(motif.name, from: "motif_id")
        click_button("Afficher les créneaux")

        find(".creneau", match: :first).click
        expect(page).to have_content("Nouveau RDV")
      end
    end

    context "when the motif is by phone and there is a plage d'ouverture without lieu" do
      let!(:motif) { create(:motif, :by_phone, bookable_publicly: true, service: agent.service, organisation: organisation) }

      it_behaves_like "book a rdv without a lieu"
    end

    context "when the motif is at home and there is a plage d'ouverture without lieu" do
      let!(:motif) { create(:motif, :at_home, bookable_publicly: true, service: agent.service, organisation: organisation) }

      it_behaves_like "book a rdv without a lieu"
    end
  end
end
