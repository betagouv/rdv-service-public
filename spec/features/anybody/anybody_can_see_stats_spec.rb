RSpec.describe "Anybody can see stats" do
  let(:organisation) { create(:organisation) }
  let(:motif) { create(:motif, :collectif, organisation:) }

  it "displays all the stats" do
    visit root_path
    click_link "Statistiques"
    expect(page).to have_current_path(stats_path)
    expect(page).to have_content("Statistiques")
    # cette page contient l’iframe metabase
    expect(page).to have_css("iframe")
  end
end
