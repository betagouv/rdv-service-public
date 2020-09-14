describe "can see users' RDV" do
  let!(:organisation) { create(:organisation) }
  let!(:agent) { create(:agent, organisations: [organisation]) }
  let!(:user) { create(:user, organisations: [organisation]) }

  before do
    login_as(agent, scope: :agent)
    visit authenticated_agent_root_path
    click_link "Vos usagers"
    click_link "Usagers"
  end

  context "with no RDV" do
    before { click_link user.full_name }
    it do
      expect(page).to have_content("0\nÀ venir")
      click_link "Voir tous les RDV précédents"
      expect_page_title("Liste des RDV")
      expect_page_with_no_record_text("Aucun RDV")
    end
  end

  context "with one RDV" do
    let!(:rdv) { create :rdv, :future, users: [user], organisation: organisation }
    before { click_link user.full_name }
    it do
      expect(page).to have_content("1\nÀ venir")
      click_link "Voir tous les RDV précédents"
      expect_page_title("Liste des RDV")
      expect(page).to have_content(rdv_title_spec(rdv))
    end
  end
end
