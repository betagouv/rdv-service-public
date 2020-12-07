describe "can see users' RDV" do
  let!(:organisation) { create(:organisation) }
  let!(:service) { create(:service) }
  let!(:agent) { create(:agent, organisations: [organisation], service: service) }
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
    let!(:motif) { create(:motif, organisation: organisation, service: service) }
    let!(:rdv) { create :rdv, :future, users: [user], organisation: organisation, motif: motif, agents: [agent] }
    before { click_link user.full_name }
    it do
      expect(page).to have_content("1\nÀ venir")
      within(".rdvs-history") do
        click_link "Voir tous les rendez-vous de #{user.full_name}"
      end
      expect_page_title("Liste des RDV")
      expect(page).to have_content(rdv_title_spec(rdv))
    end
  end
end
