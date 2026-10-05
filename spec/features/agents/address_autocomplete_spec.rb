RSpec.describe "Autocomplétion d’adresse côté agent", :js do
  let(:organisation) { create(:organisation) }
  let(:agent) { create(:agent, admin_role_in_organisations: [organisation]) }

  before do
    page.driver.with_playwright_page do |playwright_page|
      playwright_page.route("https://data.geopf.fr/geocodage/search/**", lambda { |route, _request|
        route.fulfill(
          status: 200,
          contentType: "application/json",
          body: file_fixture("geocode_result.json").read
        )
      })
    end
    login_as(agent, scope: :agent)
  end

  it "remplit les coordonnées d’un nouveau lieu à partir de la suggestion choisie" do
    visit new_admin_organisation_lieu_path(organisation)
    fill_in "Nom", with: "Mairie du 19e"
    fill_in "Adresse", with: "16 quai de la Loire"
    find("[role=option]", text: "16 Quai de la Loire").click
    expect(page).to have_field("Adresse", with: "16 Quai de la Loire, Paris, 75019")
    click_button "Enregistrer"

    expect_page_title("Lieux")
    expect(Lieu.find_by(name: "Mairie du 19e")).to have_attributes(
      address: "16 Quai de la Loire, Paris, 75019",
      latitude: 48.88393,
      longitude: 2.372095
    )
  end

  it "permet de choisir une suggestion au clavier" do
    visit new_admin_organisation_lieu_path(organisation)
    fill_in "Nom", with: "Mairie du 19e"
    fill_in "Adresse", with: "16 quai de la Loire"
    expect(page).to have_css("[role=option]", text: "16 Quai de la Loire")
    find_field("Adresse").send_keys(:down)
    page.send_keys(:enter)
    expect(page).to have_field("Adresse", with: "16 Quai de la Loire, Paris, 75019")
    click_button "Enregistrer"

    expect_page_title("Lieux")
    expect(Lieu.find_by(name: "Mairie du 19e")).to have_attributes(
      address: "16 Quai de la Loire, Paris, 75019",
      latitude: 48.88393,
      longitude: 2.372095
    )
  end

  it "indique quand aucune adresse ne correspond à la recherche" do
    page.driver.with_playwright_page do |playwright_page|
      playwright_page.route("https://data.geopf.fr/geocodage/search/**", lambda { |route, _request|
        route.fulfill(status: 200, contentType: "application/json", body: { type: "FeatureCollection", features: [] }.to_json)
      })
    end

    visit new_admin_organisation_lieu_path(organisation)
    fill_in "Adresse", with: "adresse inexistante"

    expect(page).to have_css(".autocomplete__option--no-results", text: "Nous n’avons pas trouvé d’adresse correspondant à votre recherche")
  end
end
