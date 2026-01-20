RSpec.describe "user can use a link that points to RDV search scoped to an organisation" do
  before { travel_to(Time.zone.parse("2022-09-12 15:00:00")) }

  let!(:territory) do
    create(:territory, departement_number: Territory::CN_DEPARTEMENT_NUMBER, enable_birth_date_field: true)
  end

  let!(:organisation_a) { create(:organisation, territory: territory, external_id: "123", created_at: Date.new(2022, 1, 1)) }
  let!(:organisation_b) { create(:organisation, territory: territory, external_id: "456", created_at: Date.new(2022, 1, 1)) }
  let!(:organisation_c) { create(:organisation, territory: territory, external_id: "789", created_at: Date.new(2027, 1, 1)) }

  let!(:motif_a) { create(:motif, :sectorisation_level_departement, organisation: organisation_a, name: "Motif A") }
  let!(:motif_b) { create(:motif, :sectorisation_level_departement, organisation: organisation_b, name: "Motif B") }
  let!(:motif_c) { create(:motif, :sectorisation_level_departement, organisation: organisation_c, name: "Motif C") }

  let!(:lieu_a) { create(:lieu, organisation: organisation_a) }
  let!(:lieu_b) { create(:lieu, organisation: organisation_b) }
  let!(:lieu_c) { create(:lieu, organisation: organisation_c) }

  let!(:plage_ouverture_a) { create(:plage_ouverture, motifs: [motif_a], lieu: lieu_a) }
  let!(:plage_ouverture_b) { create(:plage_ouverture, motifs: [motif_b], lieu: lieu_b) }
  let!(:plage_ouverture_c) { create(:plage_ouverture, motifs: [motif_c], lieu: lieu_c) }

  describe "accès à la réservation publique via les différentes routes publiques" do
    context "en utilisant le public_link_id de l’orga A créée en 2022" do
      it "propose les motifs de l’orga A mais pas des autres organisations" do
        visit "/org/#{organisation_a.public_link_id}"
        expect(page).to have_content("Motif A")
        expect(page).not_to have_content("Motif B")
        expect(page).not_to have_content("Motif C")
      end
    end

    context "en utilisant le public_link_id de l’orga C créée en 2027" do
      it "propose les motifs de l’orga C mais pas des autres organisations" do
        visit "/org/#{organisation_c.public_link_id}"
        expect(page).to have_content("Motif C")
        expect(page).not_to have_content("Motif A")
        expect(page).not_to have_content("Motif B")
      end
    end

    context "en utilisant l’ID incrémental stocké en base de l’orga A créée en 2022" do
      it "autorise l’accès et propose les bons motifs" do
        visit "/org/#{organisation_a.id}"
        expect(page).to have_content("Motif A")
        expect(page).not_to have_content("Motif B")
        expect(page).not_to have_content("Motif C")
      end

      it "redirige vers l’URL avec public_link_id" do
        visit "/org/#{organisation_a.public_link_id}"
        url_de_prise_de_rdv = current_url

        visit "/org/#{organisation_a.id}"
        expect(current_url).to eq(url_de_prise_de_rdv)
      end
    end

    context "en utilisant l’ID incrémental stocké en base de l’orga C créée en 2027" do
      it "refuse l’accès avec une 404" do
        expect { visit "/org/#{organisation_c.id}" }.to raise_error(ActiveRecord::RecordNotFound)
      end
    end

    context "en utilisant l’ID externe et le territory slug de l’orga A" do
      it "propose les motifs de l’orga A uniquement" do
        visit "/org/ext/#{territory.departement_number}/#{organisation_a.external_id}"
        expect(page).to have_content("Motif A")
        expect(page).not_to have_content("Motif B")
        expect(page).not_to have_content("Motif C")
      end
    end
  end

  describe "the complete process of taking a RDV from a public link" do
    around { |example| perform_enqueued_jobs { example.run } }

    it "works" do
      # On teste le domaine qui utilise les liens publics
      visit "http://www.rdv-aide-numerique-test.localhost/org/ext/#{territory.departement_number}/#{organisation_a.external_id}"
      click_on("Motif A") # choix du motif
      expect(page).to have_content("1 lieu est disponible")
      expect(page).to have_content(lieu_a.name)
      click_on(lieu_a.name)

      expect(page).to have_content("Sélectionnez un créneau")
      click_on("08:00")

      expect(page).to have_content("Vous devez vous connecter ou vous inscrire pour continuer")
      click_on("Créer un compte")

      fill_in "user_first_name", with: "David"
      fill_in "user_last_name", with: "Nchicode"
      fill_in "user_email", with: "davidnchicode@crotonmail.com"
      click_on("Je m’inscris")

      open_email("davidnchicode@crotonmail.com")
      current_email.click_link("Confirmer mon compte")

      # Page de formulaire où l'on peut ajouter le nom de naissance, la date de naissance, le téléphone...
      expect(page).to have_content("Étape 1 sur 3")
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

  context "when using the RDV Aide Numérique domain" do
    it "allows navigating back from lieu to motif selection" do
      motif_c = create(:motif, :sectorisation_level_departement,
                       organisation: organisation_a, name: "Motif C", service: motif_a.service, restriction_for_rdv: nil)
      create(:plage_ouverture, motifs: [motif_c], lieu: lieu_a)

      visit "http://www.rdv-aide-numerique-test.localhost/org/#{organisation_a.public_link_id}"
      click_on("Motif C")
      expect(page).to have_content("Motif C")

      # retour au choix de motif
      click_on("Modifier")
      expect(page).to have_content("Sélectionnez le motif de votre RDV")
    end

    it "allows navigating back from sign in to motif selection" do
      visit "http://www.rdv-aide-numerique-test.localhost/org/#{organisation_a.public_link_id}"
      click_on("Motif A") # choix du motif
      expect(page).to have_content("1 lieu est disponible")
      expect(page).to have_content(lieu_a.name)
      click_on(lieu_a.name)

      expect(page).to have_content("Sélectionnez un créneau")
      click_on("08:00")

      expect(page).to have_content("Vous devez vous connecter ou vous inscrire pour continuer")
      click_on "Modifier", match: :first

      expect(page).to have_content("Sélectionnez le motif de votre RDV")
    end
  end

  describe "links to a specific motif" do
    # On a actuellement des liens qui peuvent être sur les sites des organisations.
    #
    # Cette spec échouera si on change les routes d'une manière qui n'est pas rétro-compatible avec les
    # liens de réservation qui sont actuellement proposés.
    let!(:motif) { create(:motif, name: "Suivi de dossier") }
    let(:lieu) { create(:lieu, organisation: motif.organisation) }
    let(:agent) { create(:agent, admin_role_in_organisations: [motif.organisation]) }

    before { create(:plage_ouverture, motifs: [motif], lieu:) }

    it "still works for links that have been copied before" do
      visit "/motif/#{motif.public_link_id}/any-slug"
      expect(page).to have_content "Motif : #{motif.name}"
      expect(page).to have_content "Sélectionnez un lieu de RDV"
    end
  end
end
