RSpec.describe "Agent can CRUD plage d'ouverture" do
  let!(:organisation) { create(:organisation) }
  let!(:service) { create(:service, name: "PMI") }
  let!(:motif) { create(:motif, name: "Suivi bonjour", service: service, organisation: organisation) }
  let!(:agent) { create(:agent, service: service, admin_role_in_organisations: [organisation]) }
  let!(:lieu) { create(:lieu, organisation: organisation) }
  let!(:plage_ouverture) { create(:plage_ouverture, motifs: [motif], lieu: lieu, agent: agent, organisation: organisation, title: "Permanence") }

  before do
    login_as(agent, scope: :agent)
    visit admin_organisation_planning_plage_ouvertures_path(organisation_id: organisation.id)
  end

  shared_examples "can crud own plage ouvertures" do
    it "works", js: true do
      expect(page).to have_content("Planning de\n#{agent.reverse_full_name}") # vue liste
      click_link "Permanence"

      expect(page).to have_content("Libellé :\nPermanence")
      click_link "Modifier"

      expect(page).to have_content("Modifier votre plage d'ouverture")
      fill_in "Libellé (facultatif)", with: "La belle plage"
      click_button("Enregistrer")

      expect { perform_enqueued_jobs }.to change { emails_sent_to(agent.email).size }.by(1)
      open_email(agent.email)
      expect(current_email.subject).to eq("RDV Service Public - Plage d’ouverture modifiée - La belle plage")

      expect(page).to have_content("Planning de\n#{agent.reverse_full_name}") # vue liste
      click_on("La belle plage")
      accept_alert { click_link("Supprimer") }

      expect { perform_enqueued_jobs }.to change { emails_sent_to(agent.email).size }.by(1)
      open_email(agent.email)
      expect(current_email.subject).to eq("RDV Service Public - Plage d’ouverture supprimée - La belle plage")

      expect(page).to have_content("Planning de\n#{agent.reverse_full_name}") # vue liste
      expect(page).to have_content("Vous n'avez pas encore créé de plage d'ouverture")

      # Navigate back and forth between the list and the detail
      click_link "Créer une plage d'ouverture", match: :first
      expect(page).to have_content("Nouvelle plage d'ouverture")
      click_link("Annuler")
      expect(page).to have_content("Planning de\n#{agent.reverse_full_name}") # vue liste
      click_link "Créer une plage d'ouverture", match: :first
      expect(page).to have_content("Nouvelle plage d'ouverture")

      fill_in "Libellé (facultatif)", with: "Accueil"
      check "Suivi bonjour"
      expect(page).to have_select("plage_ouverture_lieu_id", selected: lieu.full_name) if lieu
      click_button "Créer la plage d'ouverture"
      expect(PlageOuverture.last.title).to eq("Accueil")
      expect(page).to have_content("Planning de\n#{agent.reverse_full_name}") # vue liste

      expect { perform_enqueued_jobs }.to change { emails_sent_to(agent.email).size }.by(1)
      open_email(agent.email)
      expect(current_email.subject).to eq("RDV Service Public - Plage d’ouverture créée - Accueil")
    end
  end

  context "for an agent" do
    it_behaves_like "can crud own plage ouvertures"

    describe "agenda des plages d'ouverture" do
      it "allows creation via range selection", js: true do
        click_link("Vue calendrier")
        page.driver.with_playwright_page do |playwright_page|
          playwright_page.drag_and_drop('.fc-timegrid-slot-lane[data-time="08:30:00"]', '.fc-timegrid-slot-lane[data-time="11:30:00"]')
        end

        expect(page).to have_content("Nouvelle plage d'ouverture")
        check motif.name
        fill_in "Libellé", with: "Ma petite plage de 8h30 à 12h"
        expect { click_on "Créer la plage d'ouverture" }.to change(PlageOuverture, :count).by(1)
        expected_attrs = {
          title: "Ma petite plage de 8h30 à 12h",
          start_time: Tod::TimeOfDay.new(8, 30),
          end_time: Tod::TimeOfDay.new(12, 0),
          motifs: [motif],
        }
        expect(PlageOuverture.last).to have_attributes(expected_attrs)
      end

      it "offers preferences", js: true do
        click_link("Vue calendrier")
        click_on("Préférences d’affichage")
        check "Afficher les samedis", allow_label_click: true
        expect { click_on "Enregistrer" }.to change { agent.reload.display_saturdays }.from(false).to(true)
        expect(current_path).to eq(calendar_admin_organisation_planning_plage_ouvertures_path(organisation))
      end
    end

    context "when the motif doesn't require a lieu" do
      let!(:motif) { create(:motif, :at_home, name: "Suivi bonjour", service: service, organisation: organisation) }
      let!(:lieu) { nil }

      it_behaves_like "can crud own plage ouvertures"
    end

    context "for a motif without a service" do
      let!(:motif) { create(:motif, name: "Suivi bonjour", service: nil, organisation: organisation) }

      it_behaves_like "can crud own plage ouvertures"
    end
  end

  context "for a secretaire" do
    let(:agent) { create(:agent, :secretaire, basic_role_in_organisations: [organisation]) }

    it "cannot create plage_ouverture" do
      click_link "Créer une plage d'ouverture", match: :first
      expect(page).to have_content("Aucun motif de rendez-vous ne vous est accessible. Vous devez demander à un administrateur de votre organisation d'en ajouter un")
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
      create(:plage_ouverture, :weekdays, first_day: Time.zone.today.prev_week(:monday), motifs: [motif], lieu: lieu, agent: other_agent, organisation: organisation, title: "Permanence")
    end

    it "can crud a plage_ouverture", js: true do
      visit admin_organisation_planning_plage_ouvertures_path(organisation, agent_id: other_agent.id)

      expect(page).to have_content("Planning de\nFAROU Jane") # vue liste
      expect(page).to have_content "Permanence"
      click_link "Vue calendrier"
      expect(page).to have_content "Semaine" # necessary to make sure the calendar page has loaded
      expect(page).to have_content "Permanence"
      first("a.fc-event:not(.fc-event-today)", text: "Permanence").click
      expect(page).to have_content("Libellé :\nPermanence")
      click_link "Modifier"

      expect(page).to have_content("Modifier la plage d'ouverture de Jane FAROU")
      fill_in "Libellé (facultatif)", with: "La belle plage"
      click_button("Enregistrer")

      expect(page).to have_content("Planning de\nFAROU Jane") # vue liste
      click_on("La belle plage")
      expect(page).to have_content("La belle plage")
      accept_confirm do
        click_link("Supprimer")
      end

      expect(page).to have_content("Planning de\nFAROU Jane") # vue liste
      expect(page).to have_content("Jane FAROU n'a pas encore créé de plage d'ouverture")

      click_link "Renseigner les disponibilités de Jane FAROU", match: :first

      expect(page).to have_content("Nouvelle plage d'ouverture")
      fill_in "Libellé (facultatif)", with: "Accueil"
      check "Suivi bonjour"
      expect(page).to have_select("plage_ouverture_lieu_id", selected: lieu.full_name)
      click_button "Créer la plage d'ouverture"
      expect(page).to have_content("Plage d'ouverture créée")

      expect(PlageOuverture.last.title).to eq("Accueil")
      expect(page).to have_content("Planning de\nFAROU Jane") # vue liste
    end

    context "when the motif doesn't require a lieu" do
      let!(:motif) { create(:motif, :at_home, name: "Suivi bonjour", service: service, organisation: organisation) }
      let!(:lieu) { nil }

      it "still can crud a plage_ouverture" do
        visit admin_organisation_planning_plage_ouvertures_path(organisation, agent_id: other_agent.id)

        expect(page).to have_content("Planning deFAROU Jane")
        click_link "Permanence"

        expect(page).to have_content("Libellé :\nPermanence")
        click_link "Modifier"

        expect(page).to have_content("Modifier la plage d'ouverture de Jane FAROU")
        fill_in "Libellé (facultatif)", with: "La belle plage"
        click_button("Enregistrer")

        expect(page).to have_content("Planning deFAROU Jane")
        click_on("La belle plage")
        click_link("Supprimer")

        expect(page).to have_content("Planning deFAROU Jane")
        expect(page).to have_content("Jane FAROU n'a pas encore créé de plage d'ouverture")

        click_link "Renseigner les disponibilités de Jane FAROU", match: :first

        expect(page).to have_content("Nouvelle plage d'ouverture")
        fill_in "Libellé (facultatif)", with: "Accueil"
        check "Suivi bonjour"
        click_button "Créer la plage d'ouverture"
        expect(PlageOuverture.last.title).to eq("Accueil")
        expect(page).to have_content("Planning deFAROU Jane")
      end
    end
  end

  describe "sending an email notification upon deletion" do
    let!(:plage_ouverture) { create(:plage_ouverture, motifs: [motif], agent: agent, organisation: organisation, start_time: Tod::TimeOfDay.new(8, 30), end_time: Tod::TimeOfDay.new(9, 30)) }

    it "works" do
      expect { click_link("Supprimer") }.to change(enqueued_jobs, :size).by(1)
      expect { perform_enqueued_jobs }.to change { emails_sent_to(plage_ouverture.agent.email).size }.by(1)
      open_email(plage_ouverture.agent.email)
      expect(current_email.subject).to eq("RDV Service Public - Plage d’ouverture supprimée - #{plage_ouverture.title_with_default}")
      expect(current_email.body).to include(plage_ouverture.title_with_default)
      expect(current_email.body).to include(plage_ouverture.agent.full_name)
      expect(current_email.body).to include(plage_ouverture.motifs.first.name)
      expect(current_email.body).to include("de 08:30 à 09:30") # on s'assure que les heures sont bien sérialisées et dé-sérialisées (objets Tod::TimeOfDay)
    end
  end

  describe "displaying overlapping plages on the show page" do
    let!(:overlapping_plage) do
      plage_ouverture.dup.tap do |duplicate|
        duplicate.title = "Autre plage au même moment"
        duplicate.motifs = plage_ouverture.motifs
        duplicate.save!
      end
    end

    it "works" do
      visit admin_organisation_planning_plage_ouverture_path(organisation, plage_ouverture)
      expect(page).to have_content(plage_ouverture.title_with_default)
      expect(page).to have_content("Conflit de dates et d'horaires avec d'autres plages d'ouvertures\nPlage d'ouverture #{overlapping_plage.id}")
    end
  end

  describe "detecting motif duration overflow" do
    before do
      plage_ouverture.update!(start_time: "09:00", end_time: "10:30") # plage de 1h30
      motif.update!(default_duration_in_min: 120)                     # motif de 2h
    end

    it "works" do
      visit admin_organisation_planning_plage_ouverture_path(organisation, plage_ouverture)
      expect(page).to have_content("Suivi bonjour déborde de 30 minutes. Il ne sera pas possible de prendre rendez-vous pour ce motif en l'état.")
    end
  end

  describe "selecting motifs for a plage" do
    let!(:avocat) { create(:service, name: "Avocat") }
    let!(:notaire) { create(:service, name: "Notaire") }

    context "when some motifs don't need a lieu" do
      let!(:motif_public_office) { create(:motif, organisation: organisation, service: avocat, location_type: :public_office) }
      let!(:motif_phone) { create(:motif, organisation: organisation, service: avocat, location_type: :phone) }

      it "only displays the lieu input when necessary and allows selecting multiple motifs", js: true do
        visit new_admin_organisation_planning_plage_ouverture_path(organisation, agent_id: agent)
        expect(page).not_to have_content("Lieu")
        check avocat.name
        expect(page).to have_checked_field(motif_public_office.name)
        expect(page).to have_checked_field(motif_phone.name)
        expect(page).not_to have_checked_field(motif.name)
        expect(page).to have_content("Lieu")
        expect(page).to have_select("plage_ouverture_lieu_id", selected: lieu.full_name)
        click_on "Créer la plage d'ouverture"
        expect(page).to have_content("Plage d'ouverture créée")
        expect(PlageOuverture.last.motifs).to contain_exactly(motif_public_office, motif_phone)
      end
    end

    context "when all motifs are public_office" do
      let!(:motif_public_office) { create(:motif, organisation: organisation, service: avocat, location_type: :public_office) }
      let!(:other_motif_public_office) { create(:motif, organisation: organisation, service: avocat, location_type: :public_office) }

      it "displays the lieu input (because it will always be necessary) and auto-selects the only option", js: true do
        visit new_admin_organisation_planning_plage_ouverture_path(organisation, agent_id: agent)
        expect(page).to have_content("Lieu")

        check avocat.name

        click_on "Créer la plage d'ouverture"
        expect(page).to have_content("Plage d'ouverture créée")
        expect(PlageOuverture.last.lieu).to eq lieu
      end
    end
  end

  describe "selecting a time range" do
    it "works", js: true do
      visit new_admin_organisation_planning_plage_ouverture_path(organisation, agent_id: agent)
      check motif.name
      expect(page).to have_select("plage_ouverture_lieu_id", selected: lieu.full_name)

      # Set start time at 09:30
      select "09", from: "plage_ouverture_start_time_4i"
      select "30", from: "plage_ouverture_start_time_5i"
      # Set start time at 12:00
      select "12", from: "plage_ouverture_end_time_4i"
      select "00", from: "plage_ouverture_end_time_5i"

      click_on "Ajouter une seconde période à la plage"
      # Set secondary start time at 09:30
      select "14", from: "plage_ouverture_secondary_start_time_4i"
      select "30", from: "plage_ouverture_secondary_start_time_5i"
      # Set start time at 12:00
      select "17", from: "plage_ouverture_secondary_end_time_4i"
      select "45", from: "plage_ouverture_secondary_end_time_5i"

      expect do
        click_on "Créer la plage d'ouverture"
        expect(page).to have_content("Plage d'ouverture créée")
      end.to change(PlageOuverture, :count).by(1)
      expected_attrs = {
        start_time: Tod::TimeOfDay.parse("09:30"),
        end_time: Tod::TimeOfDay.parse("12:00"),
        secondary_start_time: Tod::TimeOfDay.parse("14:30"),
        secondary_end_time: Tod::TimeOfDay.parse("17:45"),
      }
      expect(PlageOuverture.last).to have_attributes(expected_attrs)
    end
  end
end
