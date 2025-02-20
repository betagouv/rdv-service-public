RSpec.describe "Agent can create user" do
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

  context "ants_pre_demander number has the valid format" do
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
    it "considers it as uppercase when calling ANTS API and saving it in user" do
      fill_in :user_first_name, with: "Marco"
      fill_in :user_last_name, with: "Lebreton"
      fill_in :user_ants_pre_demande_number, with: "abcd1234ef"
      expect { click_button "Créer" }.to change(User, :count).by(1)
      expect(User.last.ants_pre_demande_number).to eq("ABCD1234EF")
    end
  end

  context "without any pre-demande number" do
    it "creates user with no warning" do
      fill_in :user_first_name, with: "Marco"
      fill_in :user_last_name, with: "Lebreton"
      click_button "Créer"
      expect(page).not_to have_content("déjà utilisé")
      expect_page_title("Marco LEBRETON")
      expect(User.exists?(first_name: "Marco", last_name: "Lebreton")).to be(true)
    end
  end
end
