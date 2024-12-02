RSpec.describe "Agent can create user" do
  include_context "rdv_mairie_api_authentication"

  let!(:organisation) { create(:organisation, name: "Mairie de Romainville") }
  let!(:cni_motif_category) { create(:motif_category, name: Api::Ants::EditorController::CNI_MOTIF_CATEGORY_NAME) }
  let!(:agent) { create(:agent, basic_role_in_organisations: [organisation]) }
  let(:ants_pre_demande_number) { "1122334455" }

  before do
    create(:motif, name: "Carte d'identité", organisation: organisation, restriction_for_rdv: nil, motif_category: cni_motif_category, default_duration_in_min: 25)
  end

  before do
    login_as(agent, scope: :agent)
    visit "http://www.rdv-mairie-test.localhost/"
    click_link "Usagers"
    click_link "Créer un usager", match: :first
    expect_page_title("Nouvel usager")
  end

  context "ants_pre_demander number is validated and has no appointment declared yet" do
    before do
      stub_ants_status("1122334455")
    end

    it "creates user with no warning" do
      fill_in :user_first_name, with: "Marco"
      fill_in :user_last_name, with: "Lebreton"
      fill_in :user_ants_pre_demande_number, with: ants_pre_demande_number
      click_button "Créer"
      expect(page).not_to have_content("déjà utilisé")
      expect_page_title("Marco LEBRETON")
      expect(User.exists?(first_name: "Marco", last_name: "Lebreton")).to be(true)
    end
  end

  context "when using a pre-demande number in lowercase" do
    let!(:call_to_status_with_upcased_number) { stub_ants_status("ABCD1234EF", appointments: []) }

    it "considers it as uppercase when calling ANTS API and saving it in user" do
      fill_in :user_first_name, with: "Marco"
      fill_in :user_last_name, with: "Lebreton"
      fill_in :user_ants_pre_demande_number, with: "abcd1234ef"
      expect { click_button "Créer" }.to change(User, :count).by(1)
      expect(User.last.ants_pre_demande_number).to eq("ABCD1234EF")
      expect(call_to_status_with_upcased_number).to have_been_requested.at_least_once
    end
  end

  context "ants_pre_demander number is validated but already has appointments" do
    before do
      stub_ants_status(
        "1122334455",
        appointments: [
          {
            management_url: "https://gerer-rdv.com",
            meeting_point: "Mairie de Sannois",
            appointment_date: "2023-04-03T08:45:00",
          },
        ]
      )
    end

    it "displays a warning but allows user creation" do
      fill_in :user_first_name, with: "Marco"
      fill_in :user_last_name, with: "Lebreton"
      fill_in :user_ants_pre_demande_number, with: ants_pre_demande_number
      click_button "Créer"
      expect(page).to have_content(
        "Ce numéro de pré-demande ANTS est déjà utilisé pour un RDV auprès de Mairie de Sannois. Veuillez annuler ce RDV avant d'en prendre un nouveau"
      )
      click_button("Confirmer en ignorant les avertissements")
      expect_page_title("Marco LEBRETON")
      expect(User.exists?(first_name: "Marco", last_name: "Lebreton")).to be(true)
    end
  end

  context "ants_pre_demander number is consumed (dossier déjà envoyé et instruit en préfecture)" do
    before do
      stub_ants_status("1122334455", status: "consumed")
    end

    it "prevents agent from creating the user / RDV" do
      fill_in :user_first_name, with: "Marco"
      fill_in :user_last_name, with: "Lebreton"
      fill_in :user_ants_pre_demande_number, with: ants_pre_demande_number
      click_button "Créer"
      expect(page).to have_content("Numéro de pré-demande ANTS correspond à un dossier déjà instruit")
      expect(page).not_to have_content("Confirmer en ignorant les avertissements")
    end
  end
end
