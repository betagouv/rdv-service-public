RSpec.describe "Anybody can see legal pages" do
  it "displays legal mention" do
    visit root_path
    expect(page).to have_content("Mentions Légales")
    click_link "Mentions Légales"
    expect(page).to have_selector("h1", text: "Mentions légales")
  end

  it "displays CGU" do
    visit root_path
    expect(page).to have_content("Conditions d’utilisation")
    click_link "Conditions d’utilisation"
    expect(page).to have_selector("h1", text: "Conditions d’utilisation de la plateforme RDV Solidarités")
  end

  it "displays privacy policy" do
    visit root_path
    expect(page).to have_content("Politique de confidentialité")
    click_link "Politique de confidentialité"
    expect(page).to have_selector("h1", text: "Politique de confidentialité")
  end
end
