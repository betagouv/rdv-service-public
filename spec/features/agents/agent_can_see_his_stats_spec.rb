describe "Agent can see his stats" do
  let!(:agent) { create(:agent) }

  before do
    login_as(agent, scope: :agent)
    visit authenticated_agent_root_path
  end

  shared_examples "a stats page" do
    it "displays all the stats" do
      click_link 'Vos statistiques'
      expect(page).to have_content('Statistiques')
      expect(page).to have_content('RDV créés')
    end
  end

  context "with no RDV" do
    it_behaves_like "a stats page"
  end

  context "with RDVs" do
    before { create_list :rdv, 10, :random_start }
    it_behaves_like "a stats page"
  end
end
