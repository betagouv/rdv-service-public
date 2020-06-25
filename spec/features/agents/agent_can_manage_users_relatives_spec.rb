describe "can see the relatives of the user" do
  let!(:agent) { create(:agent) }
  let!(:user) { create(:user, organisations: [Organisation.first || create(:organisation)]) }

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
    let!(:relative) { create :user, responsible: user, organisations: [Organisation.first || create(:organisation)] }
    before do
      click_link user.full_name
      click_link relative.full_name
    end
    it do
      expect(page).to have_content("Informations sur l'usager en charge")
    end
  end
end
