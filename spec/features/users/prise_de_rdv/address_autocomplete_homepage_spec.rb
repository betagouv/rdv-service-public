RSpec.describe "Autocomplétion d’adresse sur la page d’accueil de RDV Solidarités", :js do
  let(:now) { Time.zone.parse("2021-12-13 08:00") }

  let!(:territory) { create(:territory, departement_number: "75") }
  let!(:organisation) { create(:organisation, territory:) }
  let!(:motif) { create(:motif, name: "Vaccination", organisation:) }
  let!(:plage_ouverture) { create(:plage_ouverture, :weekdays, first_day: now + 1.month, motifs: [motif], organisation:) }

  before { travel_to(now) }

  it "remplit les paramètres de recherche à partir de la suggestion choisie" do
    stub_base_adresse_nationale_autocomplete_request(results: "16_quai_de_la_loire")
    visit "http://www.rdv-solidarites-test.localhost/"
    expect(page).to have_button("Rechercher", disabled: false) # initialement le bouton est actif
    fill_in "Saisissez votre adresse", with: "16 quai de la Loire"
    # tant qu'une suggestion n'est pas sélectionnée, le bouton rechercher est désactivé
    expect(page).to have_button("Rechercher", disabled: true)
    find("[role=option]", text: "16 Quai de la Loire").click
    expect(page).to have_button("Rechercher", disabled: false)
    expect(page).to have_field("Saisissez votre adresse", with: "16 Quai de la Loire, Paris, 75019")
    click_button "Rechercher"
    expect(page).to have_content("Sélectionnez le motif de votre RDV")
    expect(Rack::Utils.parse_nested_query(URI.parse(page.current_url).query)).to include(
      "address" => "16 Quai de la Loire, Paris, 75019",
      "departement" => "75",
      "city_code" => "75119",
      "street_ban_id" => "75119_5732",
      "latitude" => "48.88393",
      "longitude" => "2.372095"
    )
  end

  it "affiche un message quand aucune adresse ne correspond à la recherche" do
    stub_base_adresse_nationale_autocomplete_request(results: [])

    visit "http://www.rdv-solidarites-test.localhost/"

    fill_in "Saisissez votre adresse", with: "adresse qui nexiste pas"
    expect(page).to have_css(".autocomplete__option--no-results", text: "Nous n’avons pas trouvé d’adresse correspondant à votre recherche")
  end

  it "permet de choisir une suggestion au clavier" do
    stub_base_adresse_nationale_autocomplete_request(results: "16_quai_de_la_loire")
    visit "http://www.rdv-solidarites-test.localhost/"
    fill_in "Saisissez votre adresse", with: "16 quai de la Loire"
    expect(page).to have_css("[role=option]", text: "16 Quai de la Loire")
    find_field("Saisissez votre adresse").send_keys(:down)
    page.send_keys(:enter)
    expect(page).to have_field("Saisissez votre adresse", with: "16 Quai de la Loire, Paris, 75019")
  end
end
