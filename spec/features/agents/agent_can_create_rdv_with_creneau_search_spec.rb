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

    it "displays lieux and allow filtering on lieux" do
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

  context "when there are multiple plages from different agents in the same lieu" do
    let(:first_day) { Date.new(2023, 5, 3) }
    let!(:other_agent) { create(:agent, basic_role_in_organisations: [organisation], service: agent.service) }
    let!(:motif) { create(:motif, bookable_publicly: true, service: agent.service, organisation: organisation) }
    let!(:plage_ouverture1) { create(:plage_ouverture, motifs: [motif], first_day: first_day, agent: agent, organisation: organisation) }
    let!(:plage_ouverture2) do
      create(:plage_ouverture, motifs: [motif], first_day: first_day, agent: other_agent, organisation: organisation, lieu: plage_ouverture1.lieu)
    end

    it "displays a slot for each agent" do
      travel_to(first_day)
      visit admin_organisation_agent_searches_path(organisation)
      expect(page).to have_content("Trouver un RDV")
      select(motif.name, from: "motif_id")
      click_button("Afficher les créneaux")

      creneaux_labels = all("a.creneau").map(&:text)
      expect(creneaux_labels).to include(a_string_matching(agent.short_name))
      expect(creneaux_labels).to include(a_string_matching(other_agent.short_name))
    end
  end

  context "when there are multiple plages from the same agent in the same lieu" do
    let!(:motif) { create(:motif, bookable_publicly: true, service: agent.service, organisation: organisation) }
    let!(:plage_ouverture1) { create(:plage_ouverture, motifs: [motif], agent: agent, organisation: organisation) }
    let!(:plage_ouverture2) do
      create(:plage_ouverture, motifs: [motif], agent: agent, organisation: organisation, lieu: plage_ouverture1.lieu,
                               first_day: plage_ouverture1.first_day, ignore_benign_errors: true)
    end

    it "displays a slot for each time of the day, without duplicate times" do
      visit admin_organisation_agent_searches_path(organisation)
      expect(page).to have_content("Trouver un RDV")
      select(motif.name, from: "motif_id")
      click_button("Afficher les créneaux")

      creneaux_labels = all("a.creneau").map(&:text)
      expect(creneaux_labels).to eq(creneaux_labels.uniq) # look mom, no duplicates
    end
  end

  context "when the motif is bookable online and the next creneau is after the max booking delay" do
    let!(:motif) { create(:motif, name: "Vaccination", organisation: organisation, max_public_booking_delay: 7.days, service: agent.service) }
    let!(:plage_ouverture) { create(:plage_ouverture, :daily, first_day: 8.days.since, motifs: [motif], organisation: organisation) }

    it "still allows the agent to book a rdv, because the booking delays should only apply to agents" do
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
      it "allows the agent to book a rdv" do
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
