RSpec.describe "Agent can find a creneau for a rdv collectif" do
  let(:agent) { create(:agent, basic_role_in_organisations: [organisation]) }
  let!(:motif) do
    create(:motif, :collectif, name: "Atelier participatif", organisation: organisation)
  end
  let!(:organisation) { organisations(:default_org) }
  let!(:lieu) { create(:lieu, organisation: organisation) }

  before { login_as(agent, scope: :agent) }

  context "1 participant" do
    let!(:rdv) { create(:rdv, motif:, organisation:, agents: [agent], max_participants_count: 5, lieu:) }

    specify do
      visit admin_organisation_planning_agenda_path(organisation, agent_id: agent.id)
      click_link "Trouver un RDV", match: :first

      select "Atelier participatif", from: "Motif"
      click_button "Afficher les créneaux"

      # The rdv collectif appears in the search results
      expect(page).to have_content("Créneaux disponibles pour Atelier participatif")
      expect(page).to have_content("1 participant")
      expect(page).to have_content("4 places restantes")

      click_link "Ajouter un participant"

      expect(page).to have_current_path(edit_admin_organisation_rdvs_collectif_path(rdv.organisation, rdv))
    end
  end

  context "when there are rdvs available in two different lieux" do
    let!(:rdv) { create(:rdv, motif:, organisation:, agents: [agent], max_participants_count: 5, lieu:) }
    let!(:lieu2) { create(:lieu, organisation: organisation) }
    let!(:rdv2) do
      create(:rdv, motif: motif, organisation: organisation, agents: [agent], max_participants_count: 5, lieu: lieu2)
    end

    it "shows the list of lieux before the list of rdvs" do
      visit admin_organisation_creneaux_search_path(organisation)

      select "Atelier participatif", from: "Motif"
      click_button "Afficher les créneaux"

      expect(page).to have_content("2 lieux proposent des créneaux")
      click_link("Prochain créneau", match: :first)

      expect(page).to have_content("Créneaux disponibles pour Atelier participatif")
    end
  end

  context "en partant de la fiche usager" do
    let!(:rdv) { create(:rdv, motif:, organisation:, agents: [agent], max_participants_count: 5, lieu:) }
    let!(:user_jorja) { create(:user, first_name: "Jorja", last_name: "SMITH", organisations: [organisation]) }

    it "retient l’usager sélectionné" do
      visit admin_organisation_user_path(organisation, user_jorja)
      click_on "Trouver un RDV pour l’usager"
      select "Atelier participatif", from: "Motif"
      click_button "Afficher les créneaux"
      click_on("Ajouter Jorja SMITH")
      expect(page).to have_content("Jorja SMITH")
      click_on "Enregistrer"
      expect(page).to have_content("Participants mis à jour")
      expect(rdv.reload.users).to include(user_jorja)
    end
  end

  context "en partant de la fiche usager mais l’usager pariticpate déjà au RDV collectif" do
    let!(:user_jorja) { create(:user, first_name: "Jorja", last_name: "SMITH", organisations: [organisation]) }
    let!(:rdv) { create(:rdv, users: [user_jorja], motif:, organisation:, agents: [agent], max_participants_count: 5, lieu:) }

    it "ne propose pas de le ré-ajouter" do
      visit admin_organisation_user_path(organisation, user_jorja)
      click_on "Trouver un RDV pour l’usager"
      select "Atelier participatif", from: "Motif"
      click_button "Afficher les créneaux"
      expect(page).to have_content("1 participant dont Jorja SMITH")
      expect(page).not_to have_content("Ajouter Jorja SMITH")
      expect(page).not_to have_content("Ajouter un participant")
    end
  end
end
