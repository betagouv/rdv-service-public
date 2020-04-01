describe "can see the relatives of the user" do
  let!(:agent) { create(:agent) }
  let!(:user) { create(:user) }

  before do
    login_as(agent, scope: :agent)
    visit authenticated_agent_root_path
    click_link "Vos usagers"
  end

  context "with no relative" do
    before { click_link user.full_name }
    it { expect(page).to have_content('Aucun proche') }
  end

  context "with relatives" do
    let!(:relative) { create :user, responsible: user }
    before do
      click_link user.full_name
      click_link relative.full_name
    end
    it do
      expect(page).to have_content('Informations responsibleales')
    end
  end
end
