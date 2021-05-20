# frozen_string_literal: true

describe "Anybody can see stats" do
  it "displays all the stats" do
    visit root_path
    click_link "Statistiques"
    expect(page).to have_content("Statistiques")
    expect(page).to have_content("RDV créés")
    expect(page).to have_content("Usagers créés")
  end
end
