RSpec.describe "Autocomplétion d’adresse côté agent", :js do
  let(:territory) { create(:territory, departement_number: "75") }
  let(:organisation) { create(:organisation, territory:) }
  let(:agent) { create(:agent, admin_role_in_organisations: [organisation], role_in_territories: [territory]) }

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

  it "indique le chargement pendant la recherche" do
    page.driver.with_playwright_page do |playwright_page|
      playwright_page.route("https://data.geopf.fr/geocodage/search/**", lambda { |route, _request|
        sleep 2
        route.fulfill(status: 200, contentType: "application/json", body: file_fixture("geocode_result.json").read)
      })
    end

    visit new_admin_organisation_lieu_path(organisation)
    fill_in "Adresse", with: "16 quai de la Loire"

    expect(page).to have_css(".autocomplete__option--no-results", text: "Chargement des suggestions…")
    expect(page).to have_css("[role=option]", text: "16 Quai de la Loire", wait: 5)

    fill_in "Adresse", with: "16 quai de la Loire Paris"
    expect(page).to have_css(".autocomplete__option--no-results", text: "Chargement des suggestions…")
    expect(page).to have_no_css("[role=option]", text: "16 Quai de la Loire")
  end

  it "indique une erreur quand la recherche échoue" do
    page.driver.with_playwright_page do |playwright_page|
      playwright_page.route("https://data.geopf.fr/geocodage/search/**", ->(route, _request) { route.abort })
    end

    visit new_admin_organisation_lieu_path(organisation)
    fill_in "Adresse", with: "16 quai de la Loire"

    expect(page).to have_css(".autocomplete__option--no-results", text: "Une erreur est survenue lors de la recherche")
  end

  it "demande au moins 3 caractères, espaces exclus, sans lancer de recherche" do
    nombre_de_recherches = 0
    page.driver.with_playwright_page do |playwright_page|
      playwright_page.route("https://data.geopf.fr/geocodage/search/**", lambda { |route, _request|
        nombre_de_recherches += 1
        route.abort
      })
    end

    visit new_admin_organisation_lieu_path(organisation)
    fill_in "Adresse", with: "1"
    expect(page).to have_css(".autocomplete__option--no-results", text: "Saisissez au moins 3 caractères pour lancer la recherche")

    fill_in "Adresse", with: "10 "
    expect(page).to have_css(".autocomplete__option--no-results", text: "Saisissez au moins 3 caractères pour lancer la recherche")
    expect(nombre_de_recherches).to eq(0)
  end

  it "remplit le code BAN d’une rue de sectorisation à partir de la suggestion choisie" do
    sector = create(:sector, territory:)
    visit new_admin_territory_sector_zone_path(territory, sector, default_zone_level: "street")
    fill_in "Rechercher une rue", with: "quai de la Gironde"
    find("[role=option]", text: "Quai de la Gironde").click

    expect(page).to have_field("zone_city_name", with: "Paris")
    expect(page).to have_field("zone_city_code", with: "75119")
    expect(page).to have_field("zone_street_name", with: "Quai de la Gironde")
    expect(page).to have_field("zone_street_ban_id", with: "75119_4197")
  end
end
