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

  describe "stats by territories" do
    let!(:territory_with_stats) do
      create(:territory, public_stats: true, name: "Territoire public")
    end

    let!(:territory_without_stats) do
      create(:territory, public_stats: false, name: "Territoire secret")
    end

    it "lists the territories that are willing to publish public stats" do
    end
  end
end
