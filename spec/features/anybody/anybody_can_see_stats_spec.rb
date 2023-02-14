# frozen_string_literal: true

describe "Anybody can see stats" do
  it "displays all the stats" do
    visit root_path
    click_link "Statistiques"
    expect(page).to have_current_path(stats_path)
    expect(page).to have_content("Statistiques")
    expect(page).to have_content("RDV créés")
  end

  it "displays the number of agents with public plages or RDV collectif" do
    visit stats_path
    expect(page).to have_content("0 ont des créneaux ouverts au public")

    create(:plage_ouverture, motifs: [create(:motif, bookable_publicly: true)]) # reservable online plage
    create(:rdv, motif: create(:motif, :collectif, bookable_publicly: true)) # reservable online RDV collectif

    visit stats_path
    expect(page).to have_content("2 ont des créneaux ouverts au public")
  end
end
