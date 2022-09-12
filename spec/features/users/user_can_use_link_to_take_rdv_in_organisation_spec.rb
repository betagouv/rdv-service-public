# frozen_string_literal: true

RSpec.describe "user can use a link that points to RDV search scoped to an organisation" do
  before { travel_to(Time.zone.parse("2022-09-12 15:00:00")) }

  let!(:territory) { create(:territory, departement_number: "CN") }
  let!(:organisation_a) { create(:organisation, territory: territory, external_id: "123") }
  let!(:organisation_b) { create(:organisation, territory: territory, external_id: "456") }

  let!(:motif_a) { create(:motif, :sectorisation_level_departement, organisation: organisation_a, name: "Motif A") }
  let!(:motif_b) { create(:motif, :sectorisation_level_departement, organisation: organisation_b, name: "Motif B") }

  let!(:lieu_a) { create(:lieu, organisation: organisation_a) }
  let!(:lieu_b) { create(:lieu, organisation: organisation_b) }

  let!(:plage_ouverture_a) { create(:plage_ouverture, motifs: [motif_a], lieu: lieu_a) }
  let!(:plage_ouverture_b) { create(:plage_ouverture, motifs: [motif_b], lieu: lieu_b) }

  describe "scoping the results to the provided organisation" do
    context "when providing the internal organisation id" do
      it "scopes the motifs to the organisation" do
        visit "/p/#{organisation_a.id}"
        expect(page).to have_content("Motif A")
        expect(page).not_to have_content("Motif B")
      end
    end

    context "when providing the external organisation id + territory slug" do
      it "scopes the motifs to the organisation" do
        visit "/e/#{territory.departement_number}/#{organisation_a.external_id}"
        expect(page).to have_content("Motif A")
        expect(page).not_to have_content("Motif B")
      end
    end
  end

  describe "the complete process of taking a RDV from a public link" do
    it "works" do
      visit "/e/#{territory.departement_number}/#{organisation_a.external_id}"
      expect(page).to have_content("1 lieu est disponible")
      expect(page).to have_content(lieu_a.name)
      expect(page).to have_content(motif_a.service.name)
      click_on("Prochaine disponibilité lemardi 20 septembre 2022 à 08h00")

      expect(page).to have_content("Sélectionnez un créneau")
      click_on("08:00")

      expect(page).to have_content("Vous devez vous connecter ou vous inscrire pour continuer")
      click_on("Je m'inscris")

      fill_in "user_first_name", with: "David"
      fill_in "user_last_name", with: "Nchicode"
      fill_in "user_email", with: "davidnchicode@crotonmail.com"
      click_on("Je m'inscris")

      open_email("davidnchicode@crotonmail.com")
      current_email.click_link("Confirmer mon compte")
      fill_in "password", with: "123456"
      click_on("Enregistrer")

      # Page de formulaire où l'on peut ajouter le nom de naissance, la date de naissance, le téléphone...
      fill_in "user_birth_date", with: "02/04/1990"
      click_on("Continuer")

      # Pour l'instant cette page s'affiche même si l'on a une seule personne dans la liste des choix. :/
      expect(page).to have_content("Pour qui prenez-vous rendez-vous ?") # David est sélectionné par défaut
      click_on("Continuer")

      # Page finale de confirmation
      expect(page).to have_content("Confirmation")
      expect(page).to have_content("Date du rendez-vous : mardi 20 septembre 2022 à 08h00 (45 minutes)")
      expect { click_on("Confirmer mon RDV") }.to change(Rdv, :count).by(1)
    end
  end
end
