describe "can see users' RDV" do
  let!(:organisation) { create(:organisation) }
  let!(:agent) { create(:agent, organisations: [organisation]) }
  let!(:user) { create(:user, organisations: [organisation]) }

  before do
    login_as(agent, scope: :agent)
    visit authenticated_agent_root_path
    click_link "Usagers"
  end

  context "with no RDV" do
    before { click_link user.full_name }
    it do
      expect(page).to have_content("0\nÀ venir")
      expect(page).to have_content("aucun rendez-vous")
    end
  end

  context "with one RDV" do
    let!(:rdv) { create :rdv, :future, users: [user], organisation: organisation }
    before { click_link user.full_name }
    it do
      expect(page).to have_content("1\nÀ venir")
      click_link "Voir tous les rendez-vous de #{user.full_name}"
      expect_page_title("Liste des RDV")
      expect(page).to have_content(rdv_title_spec(rdv))
    end
  end
end
