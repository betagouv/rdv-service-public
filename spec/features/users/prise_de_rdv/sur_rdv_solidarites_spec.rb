RSpec.describe "Prise de RDV sur RDVS" do
  let(:now) { Time.zone.parse("2021-12-13 8:00") }

  around { |example| perform_enqueued_jobs { example.run } }

  before { travel_to(now) }

  context "Des motifs avec des créneaux réservables existent" do
    let!(:territory92) do
      create(:territory, departement_number: "92", enable_birth_date_field: true)
    end
    let!(:organisation) { create(:organisation, :with_contact, territory: territory92) }
    let(:service) { create(:service) }
    let!(:motif) { create(:motif, name: "Vaccination", organisation: organisation, restriction_for_rdv: nil, service: service) }
    let!(:autre_motif) { create(:motif, name: "Consultation", organisation: organisation, restriction_for_rdv: nil, service: service) }
    let!(:motif_autre_service) { create(:motif, :by_phone, name: "Télé consultation", organisation: organisation, restriction_for_rdv: nil, service: create(:service)) }
    let!(:lieu) { create(:lieu, organisation: organisation) }
    let!(:plage_ouverture) { create(:plage_ouverture, :weekdays, first_day: now + 1.month, motifs: [motif], lieu: lieu, organisation: organisation) }
    let!(:autre_plage_ouverture) { create(:plage_ouverture, :weekdays, first_day: now + 1.month, motifs: [autre_motif], lieu: lieu, organisation: organisation) }
    let!(:plage_ouverture_autre_service) { create(:plage_ouverture, :weekdays, first_day: now + 1.month, motifs: [motif_autre_service], lieu: lieu, organisation: organisation) }
    let!(:lieu2) { create(:lieu, organisation: organisation) }
    let!(:plage_ouverture2) { create(:plage_ouverture, :weekdays, first_day: now + 1.month, motifs: [motif], lieu: lieu2, organisation: organisation) }

    it "permet la recherche géographique depuis la page d'accueil", js: true do
      visit root_path

      expect(page).to have_selector("h1", text: "Prenez rendez-vous en ligne\navec votre département")
      fill_in("search_where", with: "79 Rue de Plaisance, 92250 La Garenne-Colombes")

      find("#search_departement", visible: :all) # permet d'attendre que l'élément soit dans le DOM
      page.execute_script("document.querySelector('#search_departement').value = '92'")
      page.execute_script("document.querySelector('#search_submit').disabled = false")

      click_button("Rechercher")

      expect(page).to have_content("Sélectionnez le service puis le motif pour lequel vous voulez prendre un RDV")
      find("button", text: motif.service.name).click
      find("a", text: motif.name).click

      expect(page).to have_content(lieu.name)
      expect(page).to have_content(lieu2.name)

      find(".fr-card__title", text: /#{lieu.name}/).ancestor(".fr-card__body").find("a").click

      expect(page).to have_content(lieu.name)

      expect(page).to have_current_path(
        prendre_rdv_path(
          address: "79 Rue de Plaisance, 92250 La Garenne-Colombes",
          city_code: "",
          departement: 92,
          date: "2022-01-13 08:00:00 +0100",
          latitude: "",
          lieu_id: lieu&.id,
          longitude: "",
          motif_name_with_location_type: "vaccination-public_office",
          street_ban_id: "",
          service_id: service&.id
        )
      ) # Cet expect permet de vérifier que les tests qui se basent sur ce path pour éviter des étapes intermédiaires sont corrects

      first(:link, "11:00").click

      fill_in("Prénom", with: "Michel")
      fill_in("Nom", with: "Lapin")
      fill_in("Adresse email", with: "michel@lapin.fr")
      click_button("Recevoir un code de connexion")
      fill_in("Code à 6 chiffres", with: LoginCode.most_recent_usable_for(email: "michel@lapin.fr").code)
      click_on("Valider")

      expect(page).to have_content("Confirmez votre rendez-vous")

      expect(page).to have_content("Vos informations")
      first(:field, "Date de naissance").send_keys(Time.zone.yesterday.strftime("%d/%m/%Y"))
      fill_in("Nom de naissance", with: "Lapinou") if page.has_field?("Nom de naissance")
      fill_in("Téléphone", with: "0612345678") if page.has_field?("Téléphone")

      choose("Une autre personne", allow_label_click: true)
      within(".fr-fieldset__element", text: "Une autre personne") do
        fill_in("Prénom", with: "Mathieu")
        fill_in("Nom", with: "Lapin")
        fill_in("Date de naissance", with: Date.yesterday)
      end

      click_button("Confirmer mon RDV")

      expect(page).to have_content("Votre RDV")
      expect(page).to have_content(motif.name)
      expect(page).to have_content("11h00")
      expect(Rdv.last.participations.all?(&:created_by_user?)).to be(true)
      relative = User.find_by(first_name: "Mathieu", last_name: "Lapin")
      expect(Rdv.last.users).to include(relative)
    end

    describe "quand l'usager est connecté via FranceConnect" do
      let!(:user) { create(:user, :using_france_connect, organisations: [organisation]) }

      before { login_as(user, scope: :user) }

      it "affiche la date de naissance en lecture seule, le warning FranceConnect et le champ email" do
        visit new_users_rdv_wizard_step_path(motif_id: motif.id, lieu_id: lieu.id, departement: "92", starts_at: (now + 1.month).change(hour: 8))
        expect(page).to have_content("Vos informations")
        expect(page).to have_field("Date de naissance", disabled: true)
        expect(page).to have_field("Nom de naissance", disabled: true)
        expect(page).to have_field("Prénom", disabled: true)
        # FranceConnect ne gèle pas le nom de famille (seul ProConnect le fait)
        expect(page).to have_field("Nom", disabled: false)
        expect(page).to have_content("Les champs d'état civil ne peuvent plus être modifiés suite à la connexion certifiée par FranceConnect")
        expect(page).to have_field("Email", with: user.email, disabled: true)
      end
    end
  end

  context "l'espace a le champ complément d'adresse activé" do
    let!(:territory) { create(:territory, departement_number: "92", enable_address_details: true) }
    let!(:organisation) { create(:organisation, territory:) }
    let!(:motif) { create(:motif, organisation:) }
    let!(:lieu) { create(:lieu, organisation:) }
    let!(:plage_ouverture) { create(:plage_ouverture, :weekdays, first_day: now + 1.month, motifs: [motif], lieu:, organisation:) }
    let!(:user) { create(:user, organisations: [organisation]) }

    before { login_as(user, scope: :user) }

    it "affiche le champ complément d'adresse" do
      visit new_users_rdv_wizard_step_path(motif_id: motif.id, lieu_id: lieu.id, departement: "92", starts_at: (now + 1.month).change(hour: 8))
      expect(page).to have_field("Complément d'adresse")
    end
  end

  context "l'espace a le champ caisse d'affiliation activé" do
    let!(:territory) do
      create(:territory, departement_number: "92", enable_caisse_affiliation_field: true, enable_affiliation_number_field: true)
    end
    let!(:organisation) { create(:organisation, territory:) }
    let!(:motif) { create(:motif, organisation:) }
    let!(:lieu) { create(:lieu, organisation:) }
    let!(:plage_ouverture) { create(:plage_ouverture, :weekdays, first_day: now + 1.month, motifs: [motif], lieu:, organisation:) }
    let!(:user) { create(:user, organisations: [organisation]) }

    before { login_as(user, scope: :user) }

    it "affiche les champs caisse d'affiliation et numéro d'allocataire" do
      visit new_users_rdv_wizard_step_path(motif_id: motif.id, lieu_id: lieu.id, departement: "92", starts_at: (now + 1.month).change(hour: 8))
      expect(page).to have_select("Caisse d'affiliation")
      expect(page).to have_field("Numéro d'allocataire")
    end
  end

  describe "affichage du champ logement" do
    let!(:organisation) { create(:organisation, territory:) }
    let!(:motif) { create(:motif, organisation:) }
    let!(:lieu) { create(:lieu, organisation:) }
    let!(:plage_ouverture) { create(:plage_ouverture, :weekdays, first_day: now + 1.month, motifs: [motif], lieu:, organisation:) }
    let!(:user) { create(:user, organisations: [organisation]) }

    before { login_as(user, scope: :user) }

    context "quand le territoire active le champ logement" do
      let!(:territory) { create(:territory, departement_number: "92", enable_logement_field: true) }

      it "affiche le champ logement" do
        visit new_users_rdv_wizard_step_path(motif_id: motif.id, lieu_id: lieu.id, departement: "92", starts_at: (now + 1.month).change(hour: 8))
        expect(page).to have_select("Logement")
      end
    end

    context "quand le territoire n'active pas le champ logement" do
      let!(:territory) { create(:territory, departement_number: "92") }

      it "n'affiche pas le champ logement" do
        visit new_users_rdv_wizard_step_path(motif_id: motif.id, lieu_id: lieu.id, departement: "92", starts_at: (now + 1.month).change(hour: 8))
        expect(page).not_to have_select("Logement")
      end
    end
  end

  context "plusieurs orgas proposent un motif téléphonique avec le même nom" do
    let!(:service) { create(:service) }
    let!(:territory) { create(:territory, departement_number: "92") }

    let!(:first_organisation_with_po) { create(:organisation, :with_contact, territory:) }
    let!(:first_motif) { create(:motif, :by_phone, name: "RSA orientation par téléphone", organisation: first_organisation_with_po) }
    let!(:first_plage_ouverture) do
      create(:plage_ouverture, lieu: nil, motifs: [first_motif], organisation: first_organisation_with_po, first_day: Time.zone.parse("2021-12-15"), start_time: Tod::TimeOfDay.new(11))
    end

    let!(:other_organisation_with_po) { create(:organisation, :with_contact, territory:) }
    let!(:other_motif_with_po) { create(:motif, :by_phone, name: "RSA orientation par téléphone", organisation: other_organisation_with_po) }
    let!(:other_plage_ouverture) do
      create(:plage_ouverture, lieu: nil, motifs: [other_motif_with_po], organisation: other_organisation_with_po, first_day: Time.zone.parse("2021-12-16"), start_time: Tod::TimeOfDay.new(10))
    end

    let!(:organisation_without_po) { create(:organisation, :with_contact, territory:) }
    let!(:motif_without_po) { create(:motif, :by_phone, name: "RSA orientation par téléphone", organisation: organisation_without_po) }

    it "demande de choisir l'orga et permet de prendre RDV", js: true do
      visit root_path

      expect(page).to have_selector("h1", text: "Prenez rendez-vous en ligne\navec votre département")
      fill_in("search_where", with: "79 Rue de Plaisance, 92250 La Garenne-Colombes")

      find("#search_departement", visible: :all) # permet d'attendre que l'élément soit dans le DOM
      page.execute_script("document.querySelector('#search_departement').value = '92'")
      page.execute_script("document.querySelector('#search_submit').disabled = false")

      click_button("Rechercher")

      ## Motif selection
      expect(page).to have_content(first_motif.name)
      click_link(first_motif.name)

      ## Organisation selection
      expect(page).to have_content(first_organisation_with_po.name)
      expect(page).to have_content(first_organisation_with_po.phone_number)
      expect(page).to have_content(first_organisation_with_po.website)
      expect(page).to have_content("mercredi 15 décembre 2021 à 11h00")

      expect(page).to have_content(other_organisation_with_po.name)
      expect(page).to have_content(other_organisation_with_po.phone_number)
      expect(page).to have_content(other_organisation_with_po.website)
      expect(page).to have_content("jeudi 16 décembre 2021 à 10h00")

      expect(page).not_to have_content(organisation_without_po.name)

      find(".fr-card__title", text: /#{first_organisation_with_po.name}/).ancestor(".fr-card__body").find("a").click

      first(:link, "11:00").click

      fill_in("Prénom", with: "Michel")
      fill_in("Nom", with: "Lapin")
      fill_in("Adresse email", with: "michel@lapin.fr")
      click_button("Recevoir un code de connexion")
      fill_in("Code à 6 chiffres", with: LoginCode.most_recent_usable_for(email: "michel@lapin.fr").code)
      click_on("Valider")

      expect(page).to have_content("Confirmez votre rendez-vous")

      expect(page).to have_content("Vos informations")
      fill_in("Téléphone", with: "0612345678")

      choose("Une autre personne", allow_label_click: true)
      within(".fr-fieldset__element", text: "Une autre personne") do
        fill_in("Prénom", with: "Mathieu")
        fill_in("Nom", with: "Lapin")
      end

      click_button("Confirmer mon RDV")

      expect(page).to have_content("Votre RDV")
      expect(page).to have_content(first_motif.name)
      expect(page).to have_content("11h00")
      expect(Rdv.last.participations.all?(&:created_by_user?)).to be(true)
      relative = User.find_by(first_name: "Mathieu", last_name: "Lapin")
      expect(Rdv.last.users).to include(relative)
    end
  end
end
