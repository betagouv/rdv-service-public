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
      visit stats_territories_path

      expect(page).to have_content "Territoire public"
      expect(page).not_to have_content "Territoire secret"

      click_on "Territoire public"
      expect(page).to have_content "Nombre de RDV par statut"
    end

    it "doesn't allow seeing the stats of a territory that has disabled public stats" do
      expect do
        visit stats_territory_path(territory: territory_without_stats.id)
      end.to raise_error(ActiveRecord::RecordNotFound)
    end
  end
end
