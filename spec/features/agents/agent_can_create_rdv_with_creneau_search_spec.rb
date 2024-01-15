describe "Agent can create a Rdv with creneau search" do
  include UsersHelper

  before { login_as(agent, scope: :agent) }

  let!(:organisation) { create(:organisation) }
  let!(:agent) { create(:agent, basic_role_in_organisations: [organisation]) }

  context "when there are multiple plage d'ouverture and lieux" do
    let!(:motif) { create(:motif, service: agent.services.first, organisation: organisation) }
    let!(:plage_ouverture) { create(:plage_ouverture, :daily, motifs: [motif], agent: agent, organisation: organisation) }
    let!(:plage_ouverture2) { create(:plage_ouverture, :daily, motifs: [motif], organisation: organisation) }

    it "displays lieux and allow filtering on lieux" do
      visit admin_organisation_agent_searches_path(organisation)
      expect(page).to have_content("Trouver un RDV")
      select(motif.name, from: "motif_typology_slug")
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

  context "when there is only one option for lieu, service and motif selector", js: true do
    let!(:motif) { create(:motif, service: agent.services.first, organisation: organisation) }
    let!(:plage_ouverture) { create(:plage_ouverture, :daily, motifs: [motif], agent: agent, organisation: organisation) }

    it "automatically select the option" do
      visit admin_organisation_agent_searches_path(organisation)
      expect(page).to have_content("Trouver un RDV")
      expect(page).to have_select("lieu_ids", selected: plage_ouverture.lieu_name)
      expect(page).to have_select("motif_typology_slug", selected: "Motif 1 (Sur place)")
      expect(page).to have_select("service_id", selected: agent.services.first.name)
    end
  end

  context "when there is more than one option for lieux, services and motifs selector", js: true do
    let!(:agent) { create(:agent, admin_role_in_organisations: [organisation]) }
    let!(:lieu) { create(:lieu, organisation: organisation) }
    let!(:motif) { create(:motif, service: agent.services.first, organisation: organisation) }
    let!(:motif2) { create(:motif, service: agent.services.first, organisation: organisation) }
    let!(:another_service) { create(:service) }
    let!(:another_agent) { create(:agent, service: another_service, basic_role_in_organisations: [organisation]) }
    let!(:another_lieu) { create(:lieu, organisation: organisation) }
    let!(:another_motif) { create(:motif, service: another_service, organisation: organisation) }

    it "doesnt automatically select options" do
      visit admin_organisation_agent_searches_path(organisation)
      expect(page).to have_content("Trouver un RDV")
      expect(page).to have_select("lieu_ids", selected: [])
      expect(page).to have_select("motif_typology_slug", selected: "")
      expect(page).to have_select("service_id", selected: "")
    end
  end

  context "when there are multiple plages from different agents in the same lieu" do
    before { travel_to(Date.new(2023, 5, 2)) }

    let(:first_day_of_plages) { 2.weeks.from_now.beginning_of_week.to_date }
    let!(:other_agent) { create(:agent, basic_role_in_organisations: [organisation], service: agent.services.first) }
    let!(:motif) { create(:motif, service: agent.services.first, organisation: organisation) }
    let!(:plage_ouverture1) { create(:plage_ouverture, motifs: [motif], first_day: first_day_of_plages, agent: agent, organisation: organisation) }
    let!(:plage_ouverture2) do
      create(:plage_ouverture, motifs: [motif], first_day: first_day_of_plages, agent: other_agent, organisation: organisation, lieu: plage_ouverture1.lieu)
    end

    it "displays a slot for each agent" do
      travel_to(Date.new(2023, 5, 9))
      visit admin_organisation_agent_searches_path(organisation)
      expect(page).to have_content("Trouver un RDV")
      select(motif.name, from: "motif_typology_slug")
      click_button("Afficher les créneaux")

      creneaux_labels = all("a.creneau").map(&:text)
      expect(creneaux_labels).to include(a_string_matching(agent.short_name))
      expect(creneaux_labels).to include(a_string_matching(other_agent.short_name))
    end
  end

  context "when there are multiple plages from the same agent in the same lieu" do
    let!(:motif) { create(:motif, service: agent.services.first, organisation: organisation) }
    let!(:plage_ouverture1) { create(:plage_ouverture, motifs: [motif], agent: agent, organisation: organisation) }
    let!(:plage_ouverture2) do
      create(:plage_ouverture, motifs: [motif], agent: agent, organisation: organisation, lieu: plage_ouverture1.lieu,
                               first_day: plage_ouverture1.first_day, ignore_benign_errors: true)
    end

    it "displays a slot for each time of the day, without duplicate times" do
      visit admin_organisation_agent_searches_path(organisation)
      expect(page).to have_content("Trouver un RDV")
      select(motif.name, from: "motif_typology_slug")
      click_button("Afficher les créneaux")

      creneaux_labels = all("a.creneau").map(&:text)
      expect(creneaux_labels).to eq(creneaux_labels.uniq) # look mom, no duplicates
    end
  end

  context "when the motif is bookable online and the next creneau is after the max booking delay" do
    let!(:motif) { create(:motif, name: "Vaccination", organisation: organisation, max_public_booking_delay: 7.days, service: agent.services.first) }
    let!(:plage_ouverture) { create(:plage_ouverture, :daily, first_day: 8.days.since, motifs: [motif], organisation: organisation) }

    it "still allows the agent to book a rdv, because the booking delays should only apply to agents" do
      visit admin_organisation_agent_searches_path(organisation)
      expect(page).to have_content("Trouver un RDV")
      select(motif.name, from: "motif_typology_slug")
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
        select(motif.name, from: "motif_typology_slug")
        click_button("Afficher les créneaux")

        find(".creneau", match: :first).click
        expect(page).to have_content("Nouveau RDV")
      end
    end

    context "when the motif is by phone and there is a plage d'ouverture without lieu" do
      let!(:motif) { create(:motif, :by_phone, service: agent.services.first, organisation: organisation) }

      it_behaves_like "book a rdv without a lieu"
    end

    context "when the motif is at home and there is a plage d'ouverture without lieu" do
      let!(:motif) { create(:motif, :at_home, service: agent.services.first, organisation: organisation) }

      it_behaves_like "book a rdv without a lieu"
    end
  end

  context "when secretaire searches for creneau in several organisations" do
    before do
      travel_to(Time.zone.parse("2024-01-08 09:00:00"))
    end

    let!(:service_avocat) { create(:service, name: "Avocat") }
    let!(:agent) { create(:agent, :secretaire, basic_role_in_organisations: [org1, org2]) } # nous sommes secrétaire
    let!(:agent_org1) { create(:agent, first_name: "Christine", last_name: "Un", basic_role_in_organisations: [org1]) }
    let!(:agent_org2) { create(:agent, first_name: "Alberto", last_name: "Deux", basic_role_in_organisations: [org2]) }

    let!(:org1) { create(:organisation) }
    let!(:org2) { create(:organisation) }

    let!(:motif_aide_aux_victimes_org1) { create(:motif, :by_phone, organisation: org1, name: "Aide aux victimes", service: service_avocat) }
    let!(:motif_aide_aux_victimes_org2) { create(:motif, :by_phone, organisation: org2, name: "Aide aux victimes", service: service_avocat) }
    let!(:autre_motif_org1) { create(:motif, :by_phone, organisation: org1, name: "Autre motif") }

    let!(:plage_org1) { create(:plage_ouverture, organisation: org1, agent: agent_org1, motifs: [motif_aide_aux_victimes_org1], first_day: Time.zone.tomorrow) }
    let!(:plage_org2) { create(:plage_ouverture, organisation: org2, agent: agent_org2, motifs: [motif_aide_aux_victimes_org2], first_day: Time.zone.tomorrow) }

    it "displays creneaux from all organisations" do
      visit admin_organisation_agent_searches_path(org1)
      select(org1.name, from: "Organisations")
      select(org2.name, from: "Organisations")
      click_on "Sélectionner ces organisations"
      expect(page).to have_select("Motif", options: ["", "Aide aux victimes (Par téléphone)", "Autre motif (Par téléphone)"])
      select("Aide aux victimes (Par téléphone)", from: "Motif")
      click_on "Afficher les créneaux"
      expect(page).to have_content("08:00C. UN") # créneau de l'agent 1 dans l'orga 1
      expect(page).to have_content("08:00A. DEUX") # créneau de l'agent 2 dans l'orga 2

      # on crée un RDV dans l'orga 2 alors qu'on est dans l'orga 1
      click_on "08:00A. DEUX"
      # On est bien redirigé vers l'orga 2 pour le formulaire
      expect(page).to have_current_path("/admin/organisations/#{org2.id}/rdv_wizard_step/new", ignore_query: true)
    end
  end
end
