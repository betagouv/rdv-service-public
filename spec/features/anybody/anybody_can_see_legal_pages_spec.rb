RSpec.describe "Anybody can see legal pages" do
  it "affiche les mentions légales" do
    visit root_path
    expect(page).to have_content("Mentions Légales")
    click_link "Mentions Légales"
    expect(page).to have_selector("h1", text: "Mentions légales")
  end

  it "affiche les CGU à destination des usagers" do
    visit root_path
    expect(page).to have_content("CGU - Usagers")
    click_link "CGU - Usagers"
    expect(page).to have_selector("h1", text: "Conditions générales d’utilisation « Usager »")
  end

  it "affiche les CGU à destination des agents" do
    visit root_path
    expect(page).to have_content("CGU - Agents")
    click_link "CGU - Agents"
    expect(page).to have_selector("h1", text: "Conditions générales d’utilisation « Administration territoriale - Agent »")
  end

  it "affiche la politique de confidentialité" do
    visit root_path
    expect(page).to have_content("Politique de confidentialité")
    click_link "Politique de confidentialité"
    expect(page).to have_selector("h1", text: "Politique de confidentialité")
  end
end
