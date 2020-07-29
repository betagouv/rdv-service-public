describe "can see users' RDV" do
  let!(:agent) { create(:agent) }
  let!(:user) { create(:user, organisations: [Organisation.first || create(:organisation)]) }

  before do
    login_as(agent, scope: :agent)
    visit authenticated_agent_root_path
    click_link "Vos usagers"
  end

  context "with no RDV" do
    before { click_link user.full_name }
    it do
      expect(page).to have_content("0\nÀ venir")
      click_link "Voir tous les RDV"
      expect_page_title("Liste des RDV")
      expect_page_with_no_record_text("Aucun RDV")
    end
  end

  context "with one RDV" do
    let!(:rdv) { create :rdv, :future, users: [user] }
    before { click_link user.full_name }
    it do
      expect(page).to have_content("1\nÀ venir")
      click_link "Voir tous les RDV"
      expect_page_title("Liste des RDV")
      expect(page).to have_content(rdv_title_spec(rdv))
    end
  end
end
