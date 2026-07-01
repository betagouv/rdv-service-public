RSpec.describe "Prise de RDV pour un motif ANTS" do
  include_context "rdv_mairie_api_authentication"

  let(:now) { Time.zone.parse("2021-12-13 8:00") }
  let(:territory) { create(:territory, departement_number: "78") }
  let!(:organisation) { create(:organisation, name: "Mairie de Wavignies", territory:, ants_connectable: true) }
  let(:service) { create(:service) }
  let!(:motif_category) { create(:motif_category, name: Api::Ants::EditorController::PASSPORT_MOTIF_CATEGORY_NAME) }
  let!(:passport_motif) { create(:motif, name: "Passeport", organisation:, service:, motif_category:, default_duration_in_min: 25) }

  let!(:lieu) { create(:lieu, organisation:, name: "Mairie de Sannois", address: "15 Place du Général Leclerc, Sannois, 95110") }
  let(:user) { create(:user, first_name: "Marco", last_name: "Polo", email: "marcopolo@example.com") }

  before do
    default_url_options[:host] = "http://www.rdv-service-public-test.localhost"
    travel_to(now)
    create(:plage_ouverture, :no_recurrence, first_day: now, motifs: [passport_motif], lieu:, organisation:, start_time: Tod::TimeOfDay(9), end_time: Tod::TimeOfDay.new(10))
    stub_ants_status_ok(
      "WITHAPPOIN", meeting_point_id: lieu.id, appointments:  [{
        management_url: "https://gerer-rdv.com",
        meeting_point: "Mairie de Sannois",
        appointment_date: "2023-04-03T08:45:00",
      }]
    )
    stub_ants_status_ok("NUMVALID01", meeting_point_id: lieu.id, appointments: [])
    stub_ants_status_ok("NUMVALID02", meeting_point_id: lieu.id, appointments: [])
  end

  context "1 pré-demande, pour moi même avec quelques cas d'erreur" do
    it "fonctionne" do
      visit creneaux_path(
        starts_at: "2021-12-13 9:00",
        lieu_id: lieu.id,
        motif_id: passport_motif.id,
        public_link_organisation_id: organisation.id,
        ants_pre_demandes_count: "1"
      )

      expect(page).to have_current_path("/users/sign_in")
      expect(page).to have_content("Motif : Passeport")
      expect(page).to have_content("Nombre de pré-demandes ANTS à déposer : 1")
      expect(page).to have_content("Lieu : Mairie de Sannois (15 Place du Général Leclerc, Sannois, 95110)")
      expect(page).to have_content("Date du rendez-vous : lundi 13 décembre 2021 à 09h00 (25 minutes)")

      # on vérifie que les liens retour contiennent le nombre de pré-demandes pour modifier le motif
      # lien pour modifier le motif
      expect(page).to have_link("Modifier", href: prendre_rdv_path(
        departement: organisation.territory.departement_number,
        public_link_organisation_id: organisation.id
      ))

      # lien pour modifier le nombre de pré-demandes
      expect(page).to have_link("Modifier", href: prendre_rdv_path(
        departement: organisation.territory.departement_number,
        motif_name_with_location_type: passport_motif.name_with_location_type,
        public_link_organisation_id: organisation.id
      ))

      # lien pour modifier le lieu
      expect(page).to have_link("Modifier", href: prendre_rdv_path(
        departement: organisation.territory.departement_number,
        motif_name_with_location_type: passport_motif.name_with_location_type,
        public_link_organisation_id: organisation.id,
        ants_pre_demandes_count: "1"
      ))

      # lien pour modifier le créneau
      expect(page).to have_link("Modifier", href: prendre_rdv_path(
        departement: organisation.territory.departement_number,
        lieu_id: lieu.id,
        motif_name_with_location_type: passport_motif.name_with_location_type,
        public_link_organisation_id: organisation.id,
        ants_pre_demandes_count: "1"
      ))

      login_via_6_digit_code(user.email)

      expect(page).to have_field("Numéro de pré-demande ANTS")

      # numéro absent
      expect(page).to have_checked_field("Moi-même", visible: false) # visible: false car le DSFR les cache
      expect(page).to have_unchecked_field("Une autre personne", visible: false)
      expect { click_on "Confirmer mon RDV" }.not_to change(Rdv, :count)
      expect(page).to have_content("Numéro de pré-demande ANTS doit être renseigné")
      # numéro au mauvais format
      find("label", text: "Moi-même").ancestor(".rdv-proche-selection-wrapper").fill_in "Numéro de pré-demande ANTS", with: "test"
      expect { click_on "Confirmer mon RDV" }.not_to change(Rdv, :count)
      expect(page).to have_content("Numéro de pré-demande ANTS doit comporter 10 chiffres et lettres")
      # numéro non reconnu
      field = find("label", text: "Moi-même").ancestor(".rdv-proche-selection-wrapper").find_field("Numéro de pré-demande ANTS")
      expect(field.value).to eq("TEST")
      field.fill_in with: "UNRECOGNIZ"
      # expect { click_on "Confirmer mon RDV" }.not_to change(Rdv, :count)
    end
  end

  context "2 pré-demandes dont une qui a déjà des appointments" do
    it "affiche une erreur benigne contournable" do
      visit creneaux_path(
        starts_at: "2021-12-13 9:00",
        lieu_id: lieu.id,
        motif_id: passport_motif.id,
        public_link_organisation_id: organisation.id,
        ants_pre_demandes_count: "2"
      )

      expect(page).to have_content("Nombre de pré-demandes ANTS à déposer : 2")
      expect(page).to have_content("Date du rendez-vous : lundi 13 décembre 2021 à 09h00 (50 minutes)")

      login_via_6_digit_code(user.email)

      expect(page).to have_field("Numéro de pré-demande ANTS")
      fill_in("user_ants_pre_demande_number", with: "WITHAPPOIN")
      check("Nouveau proche 1", allow_label_click: true)
      within(".fr-fieldset__element", text: "Nouveau proche 1") do
        fill_in("Prénom", with: "Alain")
        fill_in("Nom", with: "Gayab")
        fill_in("Numéro de pré-demande ANTS", with: "NUMVALID01")
      end
      click_button("Confirmer mon RDV")

      # Avertissement bénin : le numéro du user principal a déjà un RDV
      expect(page).not_to have_content("Votre rendez vous a été confirmé")
      expect(page).to have_content(
        "Ce numéro de pré-demande ANTS est déjà utilisé pour un RDV auprès de Mairie de Sannois. Veuillez annuler ce RDV avant d'en prendre un nouveau"
      )
      click_button("Confirmer en ignorant les avertissements")
      expect(page).to have_content("Votre rendez vous a été confirmé.")
      expect(user.reload.ants_pre_demande_number).to eq("WITHAPPOIN")
      expect(user.relatives.count).to eq(1)
      created_proche = user.relatives.first
      expect(created_proche.first_name).to eq("Alain")
      expect(created_proche.last_name).to eq("Gayab")
      expect(created_proche.ants_pre_demande_number).to eq("NUMVALID01")
    end

    it "redirects to the home page if visiting /prendre_rdv without params" do
      visit prendre_rdv_url
      expect(page).to have_current_path("/")
    end

    it "displays the organisation name for a public link" do
      visit public_link_to_org_url(organisation_id: organisation.public_link_id)
      expect(page).to have_content "Prenez rendez-vous avec Mairie de Wavignies"
    end
  end

  context "ajout d'un proche ANTS avec des numéros problématiques puis valide" do
    it "valide le format du numéro ANTS du proche", js: true do
      visit creneaux_url(
        starts_at: "2021-12-13 9:00",
        lieu_id: lieu.id,
        motif_id: passport_motif.id,
        public_link_organisation_id: organisation.id,
        ants_pre_demandes_count: "2"
      )

      login_via_6_digit_code(user.email)

      fill_in "user_ants_pre_demande_number", with: "NUMVALID01"

      # Activer le slot du proche via la checkbox
      check "Nouveau proche 1", allow_label_click: true

      # Remplir le slot du proche sans numéro ANTS
      within(".fr-fieldset__element", text: "Nouveau proche 1") do
        fill_in("Prénom", with: "Alain")
        fill_in("Nom", with: "Mairie")
      end
      click_button "Confirmer mon RDV"
      expect(page).to have_content("Numéro de pré-demande ANTS doit être renseigné")

      # Avec un numéro invalide
      check "Nouveau proche 1", allow_label_click: true
      within(".fr-fieldset__element", text: "Nouveau proche 1") do
        fill_in("Prénom", with: "Alain")
        fill_in("Nom", with: "Mairie")
        fill_in("Numéro de pré-demande ANTS", with: "inva lide")
      end
      fill_in "user_ants_pre_demande_number", with: "NUMVALID01"
      click_button "Confirmer mon RDV"
      expect(page).to have_content("Numéro de pré-demande ANTS doit comporter 10 chiffres et lettres")

      # Avec un numéro valide
      check "Nouveau proche 1", allow_label_click: true
      within(".fr-fieldset__element", text: "Nouveau proche 1") do
        fill_in("Prénom", with: "Alain")
        fill_in("Nom", with: "Mairie")
        fill_in("Numéro de pré-demande ANTS", with: "NUMVALID02")
      end
      fill_in "user_ants_pre_demande_number", with: "NUMVALID01"
      click_button "Confirmer mon RDV"

      expect(page).to have_content("Votre rendez vous a été confirmé.")
      expect(page).to have_content("Alain MAIRIE")
      expect(page).to have_content("Marco POLO")

      alain = User.find_by(first_name: "Alain", last_name: "Mairie")
      expect(alain.ants_pre_demande_number).to eq("NUMVALID02")
    end
  end

  context "when using a pre-demande number with invalid format (too short)" do
    it "detects wrong format without calling ANTS API an warns user" do
      visit creneaux_url(
        starts_at: "2021-12-13 9:00",
        lieu_id: lieu.id,
        motif_id: passport_motif.id,
        public_link_organisation_id: organisation.id,
        ants_pre_demandes_count: "1"
      )

      login_via_6_digit_code(user.email)

      fill_in("user_ants_pre_demande_number", with: "1234ABC")
      click_button("Confirmer mon RDV")
      expect(page).to have_content("Numéro de pré-demande ANTS doit comporter 10 chiffres et lettres")
      expect(page).not_to have_content("Confirmer en ignorant les avertissements")
    end

    context "when using a pre-demande number in lowercase" do
      let!(:call_to_status_with_upcased_number) { stub_ants_status_ok("ABCD1234EF", meeting_point_id: lieu.id, appointments: []) }

      it "considers it as uppercase when calling ANTS API and saving it in user" do
        visit creneaux_url(
          starts_at: "2021-12-13 9:00",
          lieu_id: lieu.id,
          motif_id: passport_motif.id,
          public_link_organisation_id: organisation.id,
          ants_pre_demandes_count: "1"
        )

        login_via_6_digit_code(user.email)

        fill_in("user_ants_pre_demande_number", with: "abcd1234ef")
        expect { click_button("Confirmer mon RDV") }.to change(Rdv, :count).by(1)
        expect(user.reload.ants_pre_demande_number).to eq("ABCD1234EF")
        expect(call_to_status_with_upcased_number).to have_been_requested.at_least_once
      end
    end

    context "when trying to bypass the front-end validation" do
      it "performs back-end validation and displays error" do
        visit creneaux_url(
          starts_at: "2021-12-13 9:00",
          lieu_id: lieu.id,
          motif_id: passport_motif.id,
          public_link_organisation_id: organisation.id,
          ants_pre_demandes_count: "2"
        )

        login_via_6_digit_code(user.email)

        fill_in("user_ants_pre_demande_number", with: "  ")
        click_button("Confirmer mon RDV")
        expect(page).to have_content("Numéro de pré-demande ANTS doit être renseigné")
      end
    end

    context "ANTS responds with an unexpected error" do
      before do
        stub_request_ants_status("NUMVALID02", meeting_point_id: lieu.id)
          .to_return(status: 500, body: "Internal Server Error")
      end

      it "detects wrong format without calling ANTS API an warns user" do
        visit creneaux_url(
          starts_at: "2021-12-13 9:00",
          lieu_id: lieu.id,
          motif_id: passport_motif.id,
          public_link_organisation_id: organisation.id,
          ants_pre_demandes_count: "2"
        )

        login_via_6_digit_code(user.email)

        fill_in("user_ants_pre_demande_number", with: "NUMVALID02")
        click_button("Confirmer mon RDV")
        expect(page).to have_content("Numéro de pré-demande ANTS n'a pas pu être validé à cause d'une erreur inattendue. Merci de réessayer dans 30 secondes.")
        expect(page).not_to have_content("Confirmer en ignorant les avertissements")
      end
    end
  end

  describe "Displaying the input field for ANTS PREDEMANDE NUMBER" do
    context "when the motif requires ants_predemande_number" do
      it "shows input for ants_predemande_number" do
        visit creneaux_url(
          starts_at: "2021-12-13 9:00",
          lieu_id: lieu.id,
          motif_id: passport_motif.id,
          public_link_organisation_id: organisation.id,
          ants_pre_demandes_count: "2"
        )
        expect(page).to have_content("Motif : Passeport")

        login_via_6_digit_code(user.email)

        expect(page).to have_field("Numéro de pré-demande ANTS")
      end
    end

    context "when the motif does not require ants_predemande_number" do
      let!(:retrait_motif) do
        create(:motif, name: "Retrait", organisation: organisation, service:, motif_category: nil, default_duration_in_min: 25)
      end

      before do
        create(:plage_ouverture, :no_recurrence, first_day: now, motifs: [retrait_motif], lieu: lieu, organisation: organisation, start_time: Tod::TimeOfDay(15), end_time: Tod::TimeOfDay.new(16))
      end

      it "does not show input for ants_predemande_number" do
        visit creneaux_url(
          starts_at: "2021-12-13 15:00",
          lieu_id: lieu.id,
          motif_id: retrait_motif.id,
          public_link_organisation_id: organisation.id,
          ants_pre_demandes_count: "2"
        )
        expect(page).to have_content("Motif : Retrait")

        login_via_6_digit_code(user.email)

        expect(page).not_to have_field("Numéro de pré-demande ANTS")
      end

      context "user has previous rdvs requiring ants_predemande_number" do
        before do
          agent = create(:agent, basic_role_in_organisations: [organisation], service:)
          create(:rdv, motif: passport_motif, agents: [agent], users: [user], organisation: organisation)
        end

        it "does not show input for ants_predemande_number" do
          visit creneaux_url(
            starts_at: "2021-12-13 15:00",
            lieu_id: lieu.id,
            motif_id: retrait_motif.id,
            public_link_organisation_id: organisation.id,
            ants_pre_demandes_count: "2"
          )
          expect(page).to have_content("Motif : Retrait")

          login_via_6_digit_code(user.email)

          expect(page).not_to have_field("Numéro de pré-demande ANTS")
        end
      end
    end
  end

  context "prise de RDV en direct sur RDVSP (sans passer par le moteur de l'ANTS)" do
    before { stub_ants_status_ok("TESTRDV001", meeting_point_id: lieu.id) }

    context "il n'y a pas de créneaux dispos" do
      it "incite à passer par le moteur de l'ANTS", js: true do
        visit "http://www.rdv-service-public-test.localhost/org/#{organisation.public_link_id}"
        click_on "Passeport"
        expect(page).to have_content("Nombre de pré-demandes ANTS")
        expect(find_field(find("label", text: /pré-demandes ANTS/)[:for])[:value]).to eq("1")
        # On choisit volontairement un nombre de dossiers qui va faire que le créneau sera trop long pour la PO
        4.times { click_on "+" } # js: true est important dans cette spec pour tester les boutons + et -
        click_on "-"
        expect(find_field(find("label", text: /pré-demandes ANTS/)[:for])[:value]).to eq("4")
        click_on "Valider"
        expect(page).to have_content("aucun créneau correspondant à votre recherche n'a été trouvé")
        expect(page).to have_content("Élargissez votre recherche")
      end
    end

    it "permet de choisir le nombre de dossiers à déposer" do
      visit "http://www.rdv-service-public-test.localhost/org/#{organisation.public_link_id}"
      click_on "Passeport"
      expect(page).to have_content("Nombre de pré-demandes ANTS")
      fill_in(find("label", text: /pré-demandes ANTS/)[:for], with: "2", fill_options: { clear: :backspace }) # ici on fait sans JS en remplissant le champ directement
      click_on "Valider"
      expect(page).to have_content("Sélectionnez un lieu de RDV :")
      expect(page).to have_content("Nombre de pré-demandes ANTS à déposer : 2")
      click_on "Mairie de Sannois"
      expect(page).to have_content("Sélectionnez un créneau")
      expect(page).to have_content("Nombre de pré-demandes ANTS à déposer : 2")
      click_on "09:00"
      expect(page).to have_content("Votre identité")
      expect(page).to have_content("(50 minutes)")
      # Inscription via code
      fill_in "Prénom", with: "Eloïse"
      fill_in "Nom", with: "Vanna"
      fill_in "Adresse email", with: "elo@ise.fr"
      click_button "Recevoir un code de connexion"
      fill_in "Code à 6 chiffres", with: LoginCode.most_recent_usable_for(email: "elo@ise.fr").code
      click_on "Valider"
      # Parcours post-connexion
      expect(page).to have_content("Confirmez votre rendez-vous")
      expect(page).to have_content("Vos informations")
      expect(page).to have_content("Nombre de pré-demandes ANTS à déposer : 2")
      expect(page).to have_content("(50 minutes)")
      fill_in "Numéro de pré-demande ANTS", with: "TESTRDV001", match: :first
      # Remplir le slot du proche (ants_pre_demandes_count=2 → 1 slot)
      within(".fr-fieldset__element", text: "Nouveau proche 1") do
        check "Nouveau proche 1"
        fill_in "Prénom", with: "Jean"
        fill_in "Nom", with: "Vanna"
        fill_in "Numéro de pré-demande ANTS", with: "TESTRDV001"
      end
      click_on "Confirmer mon RDV"
      expect(page).to have_content("Votre rendez vous a été confirmé")
      expect(page).to have_content("durée : 50 minutes")
    end

    context "l'usager tente de passer un nombre invalide à l'étape de séléction du nombre de pré-demandes" do
      specify do
        visit "http://www.rdv-service-public-test.localhost/org/#{organisation.public_link_id}"
        click_on "Passeport"
        expect(page).to have_content("Nombre de pré-demandes ANTS")
        fill_in(find("label", text: /pré-demandes ANTS/)[:for], with: "notanumber", fill_options: { clear: :backspace }) # ici on fait sans JS en remplissant le champ directement
        click_on "Valider"
        expect(page).to have_content("Veuillez choisir un nombre de pré-demandes entre 1 et 6")
        fill_in(find("label", text: /pré-demandes ANTS/)[:for], with: "10", fill_options: { clear: :backspace })
        click_on "Valider"
        expect(page).to have_content("Veuillez choisir un nombre de pré-demandes entre 1 et 6")
        fill_in(find("label", text: /pré-demandes ANTS/)[:for], with: "2", fill_options: { clear: :backspace })
        click_on "Valider"
        expect(page).not_to have_content("Veuillez choisir un nombre de pré-demandes entre 1 et 6")
      end
    end

    context "l'usager tente de hacker le nombre de demandes dans l'URL dans les étapes post-sign-in" do
      specify do
        login_as(user, scope: :user)
        valid_query = {
          ants_pre_demandes_count: "2",
          departement: "78",
          lieu_id: lieu.id,
          motif_id: passport_motif.id,
          starts_at: "2021-12-13 9:00",
        }
        visit(new_users_rdv_wizard_step_path(valid_query))
        expect(page).to have_selector("h2", text: "Vos informations")
        expect(page).not_to have_content("Veuillez choisir un nombre de pré-demandes entre 1 et 6")
        invalid_query = valid_query.merge(ants_pre_demandes_count: "100")
        visit(new_users_rdv_wizard_step_path(invalid_query))
        expect(page).not_to have_selector("h2", text: "Vos informations")
        expect(page).to have_content("Veuillez choisir un nombre de pré-demandes entre 1 et 6")
      end
    end

    context "l'usager tente de hacker le nombre de demandes via l'URL du formulaire", js: true do
      specify do
        login_as(user, scope: :user)
        valid_query = {
          ants_pre_demandes_count: "2",
          departement: "78",
          lieu_id: lieu.id,
          motif_id: passport_motif.id,
          starts_at: "2021-12-13 9:00",
        }
        visit(new_users_rdv_wizard_step_path(valid_query))
        expect(page).to have_selector("h2", text: "Vos informations")
        expect(page).to have_button("Confirmer mon RDV")
        # Modifier l'URL d'action du formulaire pour injecter un count invalide
        page.execute_script(%{
          var form = document.querySelector("form");
          form.action = form.action.replace("ants_pre_demandes_count=2", "ants_pre_demandes_count=100");
          document.querySelector("input[name='rdv[ants_pre_demandes_count]']").value = "100";
        })
        fill_in "user_ants_pre_demande_number", with: "TESTRDV001", match: :first
        expect { click_button "Confirmer mon RDV" }.not_to change(Rdv, :count)
        expect(page).to have_content("Veuillez choisir un nombre de pré-demandes entre 1 et 6")
      end
    end
  end
end
