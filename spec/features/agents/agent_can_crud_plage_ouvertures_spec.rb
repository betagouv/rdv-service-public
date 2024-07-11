RSpec.describe "Agent can CRUD plage d'ouverture" do
  let!(:organisation) { create(:organisation) }
  let!(:service) { create(:service, name: "PMI") }
  let!(:motif) { create(:motif, name: "Suivi bonjour", service: service, organisation: organisation) }
  let!(:agent) { create(:agent, service: service, admin_role_in_organisations: [organisation]) }
  let!(:lieu) { create(:lieu, organisation: organisation) }
  let!(:plage_ouverture) { create(:plage_ouverture, motifs: [motif], lieu: lieu, agent: agent, organisation: organisation, title: "Permanence") }
  let(:new_plage_ouverture) { build(:plage_ouverture, lieu: lieu, agent: agent, organisation: organisation) }

  before do
    login_as(agent, scope: :agent)
    visit authenticated_agent_root_path
    click_link "Plages d'ouverture"
  end

  shared_examples "can crud own plage ouvertures" do
    it "works" do
      expect_page_title("Vos plages d'ouverture")
      click_link "Permanence"

      expect_page_title("Permanence")
      click_link "Modifier"

      expect_page_title("Modifier votre plage d'ouverture")
      fill_in "Nom de la plage d'ouverture", with: "La belle plage"
      click_button("Enregistrer")

      expect_page_title("La belle plage")
      click_link("Supprimer")

      expect_page_title("Vos plages d'ouverture")
      expect(page).to have_content("Vous n'avez pas encore créé de plage d'ouverture")

      # Navigate back and forth between the list and the detail
      click_link "Créer une plage d'ouverture", match: :first
      expect_page_title("Nouvelle plage d'ouverture")
      click_link("Annuler")
      expect_page_title("Vos plages d'ouverture")
      click_link "Créer une plage d'ouverture", match: :first
      expect_page_title("Nouvelle plage d'ouverture")

      fill_in "Nom de la plage d'ouverture", with: "Accueil"
      select(lieu.full_name, from: "plage_ouverture_lieu_id") if lieu
      check "Suivi bonjour"
      click_button "Créer la plage d'ouverture"

      expect_page_title("Accueil")
      click_link "Modifier"
    end
  end

  context "for an agent" do
    it_behaves_like "can crud own plage ouvertures"

    it "can access a calendar view in the index" do
      expect(page).not_to have_css("#calendar")
      click_link("Vue calendrier")
      expect(page).to have_css("#calendar")
    end

    context "when the motif doesn't require a lieu" do
      let!(:motif) { create(:motif, :at_home, name: "Suivi bonjour", service: service, organisation: organisation) }
      let!(:lieu) { nil }

      it_behaves_like "can crud own plage ouvertures"
    end
  end

  context "for a secretaire" do
    let(:agent) { create(:agent, :secretaire, basic_role_in_organisations: [organisation]) }

    it "cannot create plage_ouverture" do
      expect_page_title("Vos plages d'ouverture")
      click_link "Créer une plage d'ouverture", match: :first
      expect(page).to have_content("Aucun motif disponible. Vous ne pouvez pas créer de plage d'ouverture.")
    end

    context "with motif for_secretariat" do
      let!(:motif) { create(:motif, :for_secretariat, name: "Suivi bonjour", service: service, organisation: organisation) }
      let!(:plage_ouverture) { create(:plage_ouverture, lieu: lieu, agent: agent, motifs: [motif], organisation: organisation, title: "Permanence") }

      it_behaves_like "can crud own plage ouvertures"

      context "when the motif doesn't require a lieu" do
        let!(:motif) { create(:motif, :at_home, :for_secretariat, name: "Suivi bonjour", service: service, organisation: organisation) }
        let!(:lieu) { nil }

        it_behaves_like "can crud own plage ouvertures"
      end
    end
  end

  context "for an other agent calendar" do
    let!(:other_agent) { create(:agent, first_name: "Jane", last_name: "FAROU", service: service, basic_role_in_organisations: [organisation]) }
    let!(:plage_ouverture) do
      create(:plage_ouverture, :daily, first_day: Time.zone.today.prev_week(:monday), motifs: [motif], lieu: lieu, agent: other_agent, organisation: organisation, title: "Permanence")
    end

    it "can crud a plage_ouverture", js: true do
      visit admin_organisation_agent_plage_ouvertures_path(organisation, other_agent.id)

      expect_page_title("Plages d'ouverture de Jane FAROU (PMI)") # vue liste
      expect(page).to have_content "Permanence"
      click_link "Vue calendrier"
      expect(page).to have_content "Semaine" # necessary to make sure the calendar page has loaded
      expect(page).to have_content "Permanence"
      first("a", text: "Permanence").click
      expect_page_title("Permanence")
      click_link "Modifier"

      expect_page_title("Modifier la plage d'ouverture de Jane FAROU")
      fill_in "Nom de la plage d'ouverture", with: "La belle plage"
      click_button("Enregistrer")

      expect_page_title("La belle plage")
      accept_confirm do
        click_link("Supprimer")
      end

      expect_page_title("Plages d'ouverture de Jane FAROU (PMI)")
      expect(page).to have_content("Jane FAROU n'a pas encore créé de plage d'ouverture")

      click_link "Créer une plage d'ouverture pour Jane FAROU", match: :first

      expect_page_title("Nouvelle plage d'ouverture")
      fill_in "Nom de la plage d'ouverture", with: "Accueil"
      check "Suivi bonjour"
      select(lieu.full_name, from: "plage_ouverture_lieu_id")
      click_button "Créer la plage d'ouverture"

      expect_page_title("Accueil")
      click_link "Modifier"
    end

    context "when the motif doesn't require a lieu" do
      let!(:motif) { create(:motif, :at_home, name: "Suivi bonjour", service: service, organisation: organisation) }
      let!(:lieu) { nil }

      it "still can crud a plage_ouverture" do
        visit admin_organisation_agent_plage_ouvertures_path(organisation, other_agent.id)

        expect_page_title("Plages d'ouverture de Jane FAROU (PMI)")
        click_link "Permanence"

        expect_page_title("Permanence")
        click_link "Modifier"

        expect_page_title("Modifier la plage d'ouverture de Jane FAROU")
        fill_in "Nom de la plage d'ouverture", with: "La belle plage"
        click_button("Enregistrer")

        expect_page_title("La belle plage")
        click_link("Supprimer")

        expect_page_title("Plages d'ouverture de Jane FAROU (PMI)")
        expect(page).to have_content("Jane FAROU n'a pas encore créé de plage d'ouverture")

        click_link "Créer une plage d'ouverture pour Jane FAROU", match: :first

        expect_page_title("Nouvelle plage d'ouverture")
        fill_in "Nom de la plage d'ouverture", with: "Accueil"
        check "Suivi bonjour"
        click_button "Créer la plage d'ouverture"

        expect_page_title("Accueil")
        click_link "Modifier"
      end
    end
  end
end
