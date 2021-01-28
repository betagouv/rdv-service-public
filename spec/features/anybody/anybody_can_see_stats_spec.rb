describe "Anybody can see stats" do
  before do
    visit root_path
  end

  shared_examples "a stats page" do
    it "displays all the stats" do
      click_link "Statistiques"
      expect(page).to have_content("Statistiques")
      expect(page).to have_content("RDV créés")
      expect(page).to have_content("Usagers créés")
      expect(page).to have_title("Statistiques Du ")
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
