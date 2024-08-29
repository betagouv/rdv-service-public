RSpec.describe "User can search rdv on rdv mairie" do
  include_context "rdv_mairie_api_authentication"

  let(:now) { Time.zone.parse("2021-12-13 8:00") }
  let!(:territory) { create(:territory, :mairies, departement_number: "MA") }
  let!(:organisation) { create(:organisation, :with_contact, territory: territory, name: "Mairie de Wavignies") }
  let(:service) { create(:service) }
  let!(:cni_motif) do
    create(:motif, name: "Carte d'identité", organisation: organisation, restriction_for_rdv: nil, service: service, motif_category: cni_motif_category, default_duration_in_min: 25)
  end
  let!(:passport_motif) do
    create(:motif, name: "Passeport", organisation: organisation, restriction_for_rdv: nil, service: service, motif_category: passport_motif_category, default_duration_in_min: 25)
  end

  let!(:cni_motif_category) { create(:motif_category, name: Api::Ants::EditorController::CNI_MOTIF_CATEGORY_NAME) }
  let!(:passport_motif_category) { create(:motif_category, name: Api::Ants::EditorController::PASSPORT_MOTIF_CATEGORY_NAME) }
  let!(:lieu) { create(:lieu, organisation: organisation, name: "Mairie de Sannois", address: "15 Place du Général Leclerc, Sannois, 95110") }
  let(:user) { create(:user, email: "jeanmairie@example.com") }

  def json_response
    JSON.parse(page.html)
  end

  before do
    default_url_options[:host] = "http://www.rdv-mairie-test.localhost"
    travel_to(now)
    create(:plage_ouverture, :no_recurrence, first_day: now, motifs: [passport_motif], lieu: lieu, organisation: organisation, start_time: Tod::TimeOfDay(9), end_time: Tod::TimeOfDay.new(10))
  end

  context "when an appointment has already been booked for this pre-demande number" do
    let(:appointments) do
      [{
        management_url: "https://gerer-rdv.com",
        meeting_point: "Mairie de Sannois",
        appointment_date: "2023-04-03T08:45:00",
      }]
    end

    before do
      stub_ants_status("1122334455", appointments: appointments)
    end

    it "allows booking a rdv through the full lifecycle of api calls" do
      visit api_ants_getManagedMeetingPoints_url
      lieux_ids = json_response.pluck("id")
      expect(lieux_ids).to eq([lieu.id.to_s])

      visit api_ants_availableTimeSlots_url(
        meeting_point_ids: lieux_ids.first,
        start_date: Date.yesterday,
        end_date: Date.tomorrow,
        reason: "PASSPORT",
        documents_number: 2
      )

      time = Time.zone.now.change(hour: 9, min: 0o0)

      expect(json_response).to eq(
        {
          lieu.id.to_s => [
            {
              "datetime" => time.strftime("%Y-%m-%dT%H:%MZ"),
              "callback_url" => creneaux_url(starts_at: time.strftime("%Y-%m-%d %H:%M"), lieu_id: lieu.id, motif_id: passport_motif.id, public_link_organisation_id: organisation.id, duration: 50),
            },
          ],
        }
      )
      creneaux_url = json_response[lieu.id.to_s].first["callback_url"]

      visit creneaux_url

      expect(page).to have_current_path("/users/sign_in")
      expect(page).to have_content("Vous devez vous connecter ou vous inscrire pour continuer")
      expect(page).to have_content("Motif : Passeport")
      expect(page).to have_content("Lieu : Mairie de Sannois (15 Place du Général Leclerc, Sannois, 95110)")
      expect(page).to have_content("Date du rendez-vous : lundi 13 décembre 2021 à 09h00 (50 minutes)")
      expect(page).to have_link("modifier", href: prendre_rdv_path(departement: "MA", public_link_organisation_id: organisation.id, duration: 50))
      expect(page).to have_link("modifier",
                                href: prendre_rdv_path(departement: "MA", motif_name_with_location_type: passport_motif.name_with_location_type, public_link_organisation_id: organisation.id,
                                                       duration: 50))
      expect(page).to have_link("modifier",
                                href: prendre_rdv_path(departement: "MA", lieu_id: lieu.id, motif_name_with_location_type: passport_motif.name_with_location_type,
                                                       public_link_organisation_id: organisation.id, duration: 50))

      fill_in("user_email", with: user.email)
      fill_in("password", with: user.password)
      click_button("Se connecter")

      expect(page).to have_field("Numéro de pré-demande ANTS")
      fill_in("user_ants_pre_demande_number", with: "1122334455")
      click_button("Continuer")
      fill_in("user_ants_pre_demande_number", with: "1122334455")
      expect(page).to have_content(
        "Ce numéro de pré-demande ANTS est déjà utilisé pour un RDV auprès de Mairie de Sannois. Veuillez annuler ce RDV avant d'en prendre un nouveau"
      )
      click_button("Confirmer en ignorant les avertissements")

      click_button("Continuer")
      click_link("Confirmer mon RDV")
      expect(page).to have_content("Votre rendez vous a été confirmé.")
      expect(user.reload.ants_pre_demande_number).to eq("1122334455")
    end

    it "displays the organisation name for a public link and a generic name otherwise" do
      visit prendre_rdv_url
      expect(page).to have_content "Prenez rendez-vous avec votre mairie"

      visit public_link_to_org_url(organisation_id: organisation.id)
      expect(page).to have_content "Prenez rendez-vous avec Mairie de Wavignies"
    end
  end

  context "with no previous appointments" do
    let(:appointments) { [] }

    before do
      stub_ants_status("1122334455", appointments: appointments)
      stub_ants_status("5544332211", appointments: [])
    end

    it "can add a relative with their ants_pre_demande_number", js: true do
      time = Time.zone.now.change(hour: 9, min: 0)
      creneaux_url = creneaux_url(starts_at: time.strftime("%Y-%m-%d %H:%M"), lieu_id: lieu.id, motif_id: passport_motif.id, public_link_organisation_id: organisation.id, duration: 50)
      visit creneaux_url

      fill_in("user_email", with: user.email)
      fill_in("password", with: user.password)
      click_button("Se connecter")

      fill_in("user_ants_pre_demande_number", with: "1122334455")
      click_button("Continuer")

      click_link("Ajouter un proche")
      fill_in("user_first_name", with: "Alain")
      fill_in("user_last_name", with: "Mairie")
      fill_in("user_ants_pre_demande_number", with: "5544332211")
      click_button("Enregistrer")
      expect(page).to have_content("Alain MAIRIE")
      expect(User.exists?(first_name: "Alain", last_name: "Mairie", ants_pre_demande_number: "5544332211")).to be(true)

      click_button("Continuer")

      click_link("Confirmer mon RDV")
      expect(page).to have_content("Votre rendez vous a été confirmé.")
    end
  end

  context "when using a pre-demande number with invalid format (too short)" do
    it "detects wrong format without calling ANTS API an warns user" do
      time = Time.zone.now.change(hour: 9, min: 0)
      creneaux_url = creneaux_url(starts_at: time.strftime("%Y-%m-%d %H:%M"), lieu_id: lieu.id, motif_id: passport_motif.id, public_link_organisation_id: organisation.id, duration: 50)
      visit creneaux_url

      fill_in("user_email", with: user.email)
      fill_in("password", with: user.password)
      click_button("Se connecter")

      fill_in("user_ants_pre_demande_number", with: "1234ABC")
      click_button("Continuer")
      expect(page).to have_content("Numéro de pré-demande ANTS doit comporter 10 chiffres et lettres")
      expect(page).not_to have_content("Confirmer en ignorant les avertissements")
    end

    context "when using a pre-demande number in lowercase" do
      let!(:call_to_status_with_upcased_number) { stub_ants_status("ABCD1234EF", appointments: []) }

      it "considers it as uppercase when calling ANTS API and saving it in user" do
        time = Time.zone.now.change(hour: 9, min: 0)
        creneaux_url = creneaux_url(starts_at: time.strftime("%Y-%m-%d %H:%M"), lieu_id: lieu.id, motif_id: passport_motif.id, public_link_organisation_id: organisation.id, duration: 50)
        visit creneaux_url

        fill_in("user_email", with: user.email)
        fill_in("password", with: user.password)
        click_button("Se connecter")

        fill_in("user_ants_pre_demande_number", with: "abcd1234ef")
        click_button("Continuer")
        click_button("Continuer")
        expect { click_link("Confirmer mon RDV") }.to change(Rdv, :count).by(1)
        expect(user.reload.ants_pre_demande_number).to eq("ABCD1234EF")
        expect(call_to_status_with_upcased_number).to have_been_requested.at_least_once
      end
    end

    context "ANTS responds with an unexpected error" do
      before do
        stub_request(:get, "https://int.api-coordination.rendezvouspasseport.ants.gouv.fr/api/status?application_ids=5544332211").to_return(
          status: 500,
          body: "Internal Server Error"
        )
      end

      it "detects wrong format without calling ANTS API an warns user" do
        time = Time.zone.now.change(hour: 9, min: 0)
        creneaux_url = creneaux_url(starts_at: time.strftime("%Y-%m-%d %H:%M"), lieu_id: lieu.id, motif_id: passport_motif.id, public_link_organisation_id: organisation.id, duration: 50)
        visit creneaux_url

        fill_in("user_email", with: user.email)
        fill_in("password", with: user.password)
        click_button("Se connecter")

        fill_in("user_ants_pre_demande_number", with: "5544332211")
        click_button("Continuer")
        expect(page).to have_content("Numéro de pré-demande ANTS n'a pas pu être validé à cause d'une erreur inattendue. Merci de réessayer dans 30 secondes.")
        expect(page).not_to have_content("Confirmer en ignorant les avertissements")
      end
    end
  end

  describe "Displaying the input field for ANTS PREDEMANDE NUMBER" do
    context "when the motif requires ants_predemande_number" do
      it "shows input for ants_predemande_number" do
        time = Time.zone.now.change(hour: 9, min: 0)
        creneaux_url = creneaux_url(starts_at: time.strftime("%Y-%m-%d %H:%M"), lieu_id: lieu.id, motif_id: passport_motif.id, public_link_organisation_id: organisation.id, duration: 50)
        visit creneaux_url
        expect(page).to have_content("Motif : Passeport")

        fill_in("user_email", with: user.email)
        fill_in("password", with: user.password)
        click_button("Se connecter")

        expect(page).to have_field("Numéro de pré-demande ANTS")
      end
    end

    context "when the motif does not require ants_predemande_number" do
      let!(:retrait_motif) do
        create(:motif, name: "Retrait", organisation: organisation, restriction_for_rdv: nil, service: service, motif_category: nil, default_duration_in_min: 25)
      end

      before do
        create(:plage_ouverture, :no_recurrence, first_day: now, motifs: [retrait_motif], lieu: lieu, organisation: organisation, start_time: Tod::TimeOfDay(15), end_time: Tod::TimeOfDay.new(16))
      end

      it "does not show input for ants_predemande_number" do
        time = Time.zone.now.change(hour: 15, min: 0)
        creneaux_url = creneaux_url(starts_at: time.strftime("%Y-%m-%d %H:%M"), lieu_id: lieu.id, motif_id: retrait_motif.id, public_link_organisation_id: organisation.id, duration: 50)
        visit creneaux_url
        expect(page).to have_content("Motif : Retrait")

        fill_in("user_email", with: user.email)
        fill_in("password", with: user.password)
        click_button("Se connecter")

        expect(page).not_to have_field("Numéro de pré-demande ANTS")
      end

      context "user has previous rdvs requiring ants_predemande_number" do
        before do
          agent = create(:agent, basic_role_in_organisations: [organisation], service: service)
          create(:rdv, motif: passport_motif, agents: [agent], users: [user], organisation: organisation)
        end

        it "does not show input for ants_predemande_number" do
          time = Time.zone.now.change(hour: 15, min: 0)
          creneaux_url = creneaux_url(starts_at: time.strftime("%Y-%m-%d %H:%M"), lieu_id: lieu.id, motif_id: retrait_motif.id, public_link_organisation_id: organisation.id, duration: 50)
          visit creneaux_url
          expect(page).to have_content("Motif : Retrait")

          fill_in("user_email", with: user.email)
          fill_in("password", with: user.password)
          click_button("Se connecter")

          expect(page).not_to have_field("Numéro de pré-demande ANTS")
        end
      end
    end
  end
end
