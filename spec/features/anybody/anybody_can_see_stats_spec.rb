describe "User can see stats" do
  before do
    visit root_path
    click_link 'Statistiques'
  end

  shared_examples "a stats page" do
    it "displays all the stats" do
      expect(page).to have_content('Statistiques')
      expect(page).to have_content('RDV créés')
      expect(page).to have_content('Usagers créés')
    end
  end

  context "with no RDV" do
    it_behaves_like "a stats page"
  end

  context "with RDVs" do
    it_behaves_like "a stats page"
  end
end
