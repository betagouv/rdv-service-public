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

  it "displays the number of agents with public plages or RDV collectif on the territory scoped page" do
    visit stats_territory_path(territory: organisation.territory)
    expect(page).to have_content("0 ont des créneaux ouverts au public")

    create(:plage_ouverture, motifs: [create(:motif, organisation:)], organisation:) # reservable online plage
    create(:rdv, motif:, organisation:) # reservable online RDV collectif

    visit stats_territory_path(territory: organisation.territory)
    expect(page).to have_content("2 ont des créneaux ouverts au public")
  end
end
