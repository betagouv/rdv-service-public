describe "Creating a new account for a new project, other than a mairie", js: true do
  let(:super_admin) { create(:super_admin, :support) }

  let(:autocomplete_response) do
    <<~JSON
      {"type":"FeatureCollection","version":"draft","features":[{"type":"Feature","geometry":{"type":"Point","coordinates":[2.429639,48.880505]},"properties":{"label":"Rue de Romainville 93230 Romainville","score":0.51,"id":"93063_8160","name":"Rue de Romainville","postcode":"93230","citycode":"93063","x":658170.04,"y":6864649.51,"city":"Romainville","context":"93, Seine-Saint-Denis, Île-de-France","type":"street","importance":0.58716,"street":"Rue de Romainville"}}],"attribution":"BAN","licence":"ETALAB-2.0","query":"Place de la mairie, Romainville, 93230","limit":5}
    JSON
  end

  before do
    stub_request(:get, "https://api-adresse.data.gouv.fr/search/?q=Place%20de%20la%20mairie,%20Romainville,%2093230")
      .to_return(status: 200, body: autocomplete_response, headers: {})

    create(:service, name: "Urbanisme")
  end

  it "creates a new organisation" do
    login_as(super_admin, scope: :super_admin)
    visit super_admins_root_path

    click_link "Comptes"
    click_link "Création compte"

    fill_in("Nom du territoire", with: "France Rénov")
    fill_in("Nom de la première organisation", with: "Agence de Romainville")
    fill_in("Adresse du premier lieu", with: "Place de la mairie, Romainville, 93230")

    expect(page).to have_content("Admin de territoire")

    fill_in("Prénom", with: "Francis")
    fill_in("Nom", with: "Factice")
    fill_in("Email", with: "francis@factice.org")
    select("Urbanisme", from: "Service")

    click_button("Enregistrer")
    expect(page).to have_content("Mairie compte a été correctement créé(e).")
    # TODO: lister les services à activer dans le territoire ?
    expect(Organisation.count).to eq(1)

    new_territory = Territory.last
    expect(new_territory).to have_attributes(
      name: "France Rénov"
    )
  end
end
