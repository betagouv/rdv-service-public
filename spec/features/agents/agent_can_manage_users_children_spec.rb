describe "can see the children of the user" do
  let!(:agent) { create(:agent) }
  let!(:user) { create(:user) }

  before do
    login_as(agent, scope: :agent)
    visit authenticated_agent_root_path
    click_link "Vos usagers"
  end

  context "with no child" do
    before { click_link user.full_name }
    it { expect(page).to have_content('Aucun enfant') }
  end

  context "with children" do
    let!(:child) { create :user, parent: user }
    before do
      click_link user.full_name
      click_link child.full_name
    end
    it do
      expect(page).to have_content('Informations parentales')
    end
  end
end
