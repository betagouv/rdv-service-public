RSpec.describe "prescripteur can create RDV for a user" do
  include_context "rdv_mairie_api_authentication"

  let(:now) { Time.zone.parse("2021-12-13 8:00") }
  let!(:territory) { create(:territory, :mairies) }
  let!(:organisation) { create(:organisation, :with_contact, territory: territory) }
  let(:service) { create(:service) }
  let!(:cni_motif) do
    create(:motif, name: "Carte d'identité", organisation: organisation, restriction_for_rdv: nil, service: service, motif_category: cni_motif_category)
  end
  let!(:passport_motif) do
    create(:motif, name: "Passeport", organisation: organisation, restriction_for_rdv: nil, service: service, motif_category: passport_motif_category)
  end

  let!(:cni_motif_category) { create(:motif_category, name: Api::Ants::EditorController::CNI_MOTIF_CATEGORY_NAME) }
  let!(:passport_motif_category) { create(:motif_category, name: Api::Ants::EditorController::PASSPORT_MOTIF_CATEGORY_NAME) }
  let!(:lieu) { create(:lieu, organisation: organisation, name: "Mairie de Sannois", address: "15 Place du Général Leclerc, Sannois, 95110") }
  let(:user) { create(:user, email: "jeanmairie@example.com") }
  let(:ants_pre_demande_number) { "1122334455" }

  def json_response
    JSON.parse(page.html)
  end

  def fill_up_prescripteur
    fill_in "Votre prénom", with: "Alex"
    fill_in "Votre nom", with: "Prescripteur"
    fill_in "Votre email professionnel", with: "alex@prescripteur.fr"
    fill_in "Votre numéro de téléphone", with: "0611223344"
    click_on "Continuer"
  end

  def fill_up_user(ants_pre_demande_number:)
    expect(page).to have_content("Prescripteur : Alex PRESCRIPTEUR")
    fill_in "Prénom", with: "Patricia"
    fill_in "Nom", with: "Duroy"
    fill_in "Téléphone", with: "0611223344"
    fill_in "Numéro de pré-demande ANTS", with: ants_pre_demande_number
  end

  before do
    default_url_options[:host] = "http://www.rdv-mairie-test.localhost"
    travel_to(now)
    create(:plage_ouverture, :no_recurrence, first_day: now, motifs: [passport_motif], lieu: lieu, organisation: organisation, start_time: Tod::TimeOfDay(9), end_time: Tod::TimeOfDay.new(10))
  end

  context "success scenario (ants_pre_demander number is validated and has no appointment declared yet)" do
    before do
      stub_request(:get, %r{https://int.api-coordination.rendezvouspasseport.ants.gouv.fr/api/status}).to_return(
        status: 200,
        body: { ants_pre_demande_number => { status: "validated", appointments: [] } }.to_json
      )
    end

    it "allows booking a rdv for the given ants_pre_demander" do
      visit creneaux_url
      click_on "Je suis un prescripteur qui oriente un bénéficiaire"

      fill_up_prescripteur
      fill_up_user(ants_pre_demande_number: ants_pre_demande_number)
      click_on "Confirmer le rendez-vous"

      expect(page).to have_content("Rendez-vous confirmé")
      expect(page).to have_content("Patricia DUROY")
      expect(enqueued_jobs.pluck("job_class")).to include("Ants::SyncAppointmentJob", "SmsJob")
    end
  end

  context "ants_pre_demander number is validated but already has appointments" do
    before do
      stub_request(:get, %r{https://int.api-coordination.rendezvouspasseport.ants.gouv.fr/api/status}).to_return(
        status: 200,
        body: {
          ants_pre_demande_number => {
            status: "validated",
            appointments: [
              {
                management_url: "https://gerer-rdv.com",
                meeting_point: "Mairie de Sannois",
                appointment_date: "2023-04-03T08:45:00",
              },
            ],
          },
        }.to_json
      )
    end

    it "show a warning but allows creating the user and RDV" do
      visit creneaux_url
      click_on "Je suis un prescripteur qui oriente un bénéficiaire"

      fill_up_prescripteur
      fill_up_user(ants_pre_demande_number: ants_pre_demande_number)
      click_on "Confirmer le rendez-vous"

      expect(page).to have_content("Ce numéro de pré-demande ANTS est déjà utilisé pour un RDV auprès de Mairie de Sannois. Veuillez annuler ce RDV avant d'en prendre un nouveau")
      expect do
        click_button("Confirmer en ignorant les avertissements")
      end.to change { User.exists?(ants_pre_demande_number: ants_pre_demande_number) }.from(false).to(true)

      expect(page).to have_content("Rendez-vous confirmé")
      expect(page).to have_content("Patricia DUROY")
      expect(enqueued_jobs.pluck("job_class")).to include("Ants::SyncAppointmentJob", "SmsJob")
    end
  end

  context "ants_pre_demander number is consumed (dossier déjà envoyé et instruit en préfecture)" do
    before do
      stub_request(:get, %r{https://int.api-coordination.rendezvouspasseport.ants.gouv.fr/api/status}).to_return(
        status: 200,
        body: { ants_pre_demande_number => { status: "consumed", appointments: [] } }.to_json
      )
    end

    it "prevents from creating the user / RDV" do
      visit creneaux_url
      click_on "Je suis un prescripteur qui oriente un bénéficiaire"

      fill_up_prescripteur
      fill_up_user(ants_pre_demande_number: ants_pre_demande_number)
      click_on "Confirmer le rendez-vous"

      expect(page).to have_content("Ce numéro de pré-demande ANTS correspond à un dossier déjà instruit")
      expect(page).not_to have_content("Confirmer en ignorant les avertissements")
    end
  end

  context "quand le prescripteur saisit un numéro de pré-demande invalide" do
    let(:ants_pre_demande_number) { "AABB" } # Numéro trop court

    it "affiche un message d'erreur pour le signaler" do
      visit creneaux_url
      click_on "Je suis un prescripteur qui oriente un bénéficiaire"

      fill_up_prescripteur
      fill_up_user(ants_pre_demande_number: "AABB")
      # mock_ants_status_invalid_application_id(application_id: "AABB")
      click_on "Confirmer le rendez-vous"

      expect(page).to have_content("ne fait pas la bonne longueur (doit comporter 10 caractères)")
      expect(page).not_to have_content("Confirmer en ignorant les avertissements")
      expect(WebMock).not_to have_requested(:any, %r{int.api-coordination.rendezvouspasseport.ants.gouv.fr/api/status})

      fill_in "Numéro de pré-demande ANTS", with: "AABBCCDDEE"
      mock_ants_status(application_id: "AABBCCDDEE")
      click_on "Confirmer le rendez-vous"
      expect(page).to have_content("Rendez-vous confirmé")
      expect(Rdv.last.users.first.ants_pre_demande_number).to eq("AABBCCDDEE")
      expect(WebMock).to have_requested(:get, %r{int.api-coordination.rendezvouspasseport.ants.gouv.fr/api/status})
    end
  end

  context "ants_pre_demander number is invalid (too short)" do
    let(:ants_pre_demande_number) { "123" }

    it "prevents from creating the user / RDV" do
      visit creneaux_url
      click_on "Je suis un prescripteur qui oriente un bénéficiaire"

      fill_up_prescripteur_and_user
      click_on "Confirmer le rendez-vous"

      expect(page).to have_content("Numéro de pré-demande doit comporter 10 chiffres et lettres")
      expect(page).not_to have_content("Confirmer en ignorant les avertissements")
    end
  end

  def creneaux_url
    visit api_ants_availableTimeSlots_url(
      meeting_point_ids: lieu.id.to_s,
      start_date: Date.yesterday,
      end_date: Date.tomorrow,
      reason: "PASSPORT"
    )
    json_response[lieu.id.to_s].first["callback_url"]
  end
end
