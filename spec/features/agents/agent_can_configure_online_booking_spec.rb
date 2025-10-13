RSpec.describe "Agents can configure online booking" do
  let!(:organisation) { create(:organisation) }
  let!(:motif) do
    create(:motif, organisation: organisation, service: agent.services.first, bookable_by: :agents, collectif: false, name: "Motif individuel")
  end
  let!(:agent) { create(:agent, :cnfs, admin_role_in_organisations: [organisation]) }

  before { login_as(agent, scope: :agent) }

  describe "full lifecycle" do
    let!(:motif_for_prescripteurs) do
      create(:motif, organisation: organisation, service: agent.services.first, bookable_by: :agents_and_prescripteurs, collectif: false, name: "Suivi de dossier")
    end

    specify do
      visit admin_organisation_online_booking_path(organisation)

      expect(page).to have_content("Pour quels motifs souhaitez-vous activer la prise de rendez-vous en ligne ?")

      click_on "Enregistrer"

      expect(page).to have_content("Vous devez choisir au moins un motif pour ouvrir la réservation en ligne")
      expect(page).to have_content("Pour quels motifs souhaitez-vous activer la prise de rendez-vous en ligne ?")

      find("label", text: motif.name).click
      click_on "Enregistrer"

      expect(page).to have_content("Le motif Motif individuel est ouvert pour la réservation en ligne.")
      expect(motif.reload).to have_attributes(bookable_by: "everyone")
      expect(motif_for_prescripteurs.reload).to have_attributes(bookable_by: "agents_and_prescripteurs") # Les motifs qui ne sont pas bookable_by_everyone ne changent pas de niveau de réservation.

      expect(page).to have_content("Ouvrir une plage d'ouverture")

      visit edit_admin_organisation_online_booking_path(organisation)

      find("label", text: motif.name).click
      find("label", text: motif_for_prescripteurs.name).click
      click_on "Enregistrer"

      expect(motif.reload).to have_attributes(bookable_by: "agents")
      expect(motif_for_prescripteurs.reload).to have_attributes(bookable_by: "everyone")

      expect(page).to have_content("La liste des motifs ouverts à la réservation en ligne a été mise à jour.")

      visit edit_admin_organisation_online_booking_path(organisation)

      find("label", text: motif_for_prescripteurs.name).click
      click_on "Enregistrer"

      expect(page).to have_content("La réservation en ligne a été fermée")
      expect(motif.reload).to have_attributes(bookable_by: "agents")
      expect(motif_for_prescripteurs.reload).to have_attributes(bookable_by: "agents")

      expect(page).to have_content("Pour quels motifs souhaitez-vous activer la prise de rendez-vous en ligne ?")
    end
  end

  context "motif individuel" do
    it "displays the motif's status" do
      visit admin_organisation_online_booking_path(organisation)

      find("label", text: motif.name).click
      click_on "Enregistrer"

      expect(page).to have_content("Réservable en ligne")

      expect(page).to have_css("i.fa-solid.fa-circle-check.color-scheme-green", count: 1)
      expect(page).to have_css("i.fa-regular.fa-circle-xmark.color-scheme-red", count: 2)

      click_link("ajouter")
      expect(page).to have_checked_field(motif.name)

      create(:plage_ouverture, motifs: [motif], agent: agent, organisation: organisation)

      visit admin_organisation_online_booking_path(organisation)
      expect(page).to have_css("i.fa-solid.fa-circle-check.color-scheme-green", count: 3)
      expect(page).not_to have_css("i.fa-regular.fa-circle-xmark.color-scheme-red")
      expect(page).to have_content("1 plage d'ouverture")
    end

    it "doesn't show plages d'ouverture in the past" do
      create(:plage_ouverture, motifs: [motif], agent: agent, organisation: organisation, first_day: 20.days.from_now)
      create(:plage_ouverture, motifs: [motif], agent: agent, organisation: organisation, first_day: 10.days.ago)
      motif.update!(bookable_by: :everyone)

      visit admin_organisation_online_booking_path(organisation)

      expect(page).to have_content("1 plage d'ouverture")
    end
  end

  context "motif collectif" do
    let!(:motif) do
      create(:motif, organisation: organisation, service: agent.services.first, collectif: true, name: "Motif collectif", bookable_by: :agents)
    end

    it "displays the motif's status" do
      visit admin_organisation_online_booking_path(organisation)

      find("label", text: motif.name).click
      click_on "Enregistrer"

      create(:rdv, motif: motif, max_participants_count: 5, organisation:)

      visit admin_organisation_online_booking_path(organisation)
      expect(page).to have_css("i.fa-solid.fa-circle-check.color-scheme-green", count: 3)
      expect(page).not_to have_css("i.fa-regular.fa-circle-xmark.color-scheme-red")
      expect(page).to have_content("1 rendez-vous avec des places disponibles")
    end
  end

  describe "booking link" do
    before { motif.update!(bookable_by: :everyone) }

    context "when organisation is sectorized" do
      before do
        sector = create(:sector, territory: organisation.territory)
        create(:sector_attribution, :level_organisation, sector: sector, organisation: organisation)
        create(:motif, :sectorisation_level_organisation, organisation: organisation)
      end

      it "points to the public booking home page" do
        visit admin_organisation_online_booking_path(organisation)
      end
    end

    context "when organisation is not sectorized" do
      it "points to the public booking home page" do
        visit admin_organisation_online_booking_path(organisation)
        expect(page).to have_content("http://www.rdv-solidarites-test.localhost:#{Capybara.server_port}/org/#{organisation.id}/#{organisation.slug}")
      end
    end
  end

  describe "choix du type d'usager qui participer au rendez-vous" do
    before do
      visit edit_user_type_admin_organisation_online_booking_path(organisation)
    end

    it "permet de passer de particulier à professionnel" do
      find("label", text:  "des particuliers").click
      find("label", text:  "des professionnels").click
      click_on "Enregistrer"

      expect(page).to have_content "Profil des usagers mis à jour"

      expect(organisation.reload).to have_attributes(
        online_booking_for_particuliers: false,
        online_booking_for_professionnels: true
      )
    end

    context "si on ne remplit aucune des options" do
      it "affiche un message d'erreur" do
        find("label", text:  "des particuliers").click
        click_on "Enregistrer"
        expect(page).to have_content "Vous devez choisir au moins un type d'usager entre particulier et professionnels."

        expect(organisation.reload).to have_attributes(
          online_booking_for_particuliers: true,
          online_booking_for_professionnels: false
        )
      end
    end
  end
end
