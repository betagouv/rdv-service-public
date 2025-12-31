RSpec.describe "Creating a new account for a new project, which can be a mairie", js: true do
  let(:super_admin) { create(:super_admin, :support) }
  let!(:tag_france_services) { create(:tag, name: "France Services") }
  let!(:tag_france_titres) { create(:tag, name: "France Titres") }

  let(:autocomplete_response) do
    <<~JSON
      {"type":"FeatureCollection","version":"draft","features":[{"type":"Feature","geometry":{"type":"Point","coordinates":[2.429639,48.880505]},"properties":{"label":"Rue de Romainville 93230 Romainville","score":0.51,"id":"93063_8160","name":"Rue de Romainville","postcode":"93230","citycode":"93063","x":658170.04,"y":6864649.51,"city":"Romainville","context":"93, Seine-Saint-Denis, Île-de-France","type":"street","importance":0.58716,"street":"Rue de Romainville"}}],"attribution":"BAN","licence":"ETALAB-2.0","query":"Place de la mairie, Romainville, 93230","limit":5}
    JSON
  end

  before do
    stub_request(:get, "https://data.geopf.fr/geocodage/search/?q=Place%20de%20la%20mairie,%20Romainville,%2093230")
      .to_return(status: 200, body: autocomplete_response, headers: {})
  end

  it "creates a new organisation" do
    login_as(super_admin, scope: :super_admin)
    visit super_admins_root_url(host: "http://www.rdv-service-public-test.localhost")

    click_link "Ouverture de compte"

    fill_in("Nom de l'espace", with: "France Rénov")
    select("Commune", from: "Catégorie de l'espace")
    fill_in("Nom de la première organisation", with: "Agence de Romainville")
    fill_in("Adresse du premier lieu", with: "Place de la mairie, Romainville, 93230")

    # Fake autocomplete
    page.execute_script("document.querySelector('#compte_lieu_latitude').value = '48.880505'")
    page.execute_script("document.querySelector('#compte_lieu_longitude').value = '2.429639'")

    fill_in("Numéro du département", with: "FR")

    expect(page).to have_content("Admin d'espace")

    fill_in("Prénom", with: "Francis")
    fill_in(:compte_agent_last_name, with: "Factice") # Plusieurs champs ont le label "Nom", donc on utilise le name de l'input
    fill_in("Adresse mail", with: "francis@factice.org")

    click_button("Enregistrer")
    expect(page).to have_content("Le nouvel espace a été créé, et une invitation a été envoyée à francis@factice.org")

    expect(page).to have_content("Francis FACTICE")
    expect(Organisation.count).to eq(1)

    new_territory = Territory.last
    expect(new_territory).to have_attributes(
      name: "France Rénov",
      category: "Commune"
    )

    new_territory.admin_agents.first

    expect(new_territory.services).to be_empty
    expect(new_territory.tags).to be_empty

    new_organisation = new_territory.organisations.first
    expect(new_organisation).to have_attributes(
      name: "Agence de Romainville"
    )

    new_lieu = new_organisation.lieux.first
    expect(new_lieu).to have_attributes(
      name: "Agence de Romainville",
      latitude: 48.880505,
      longitude: 2.429639
    )

    expect(new_organisation.motifs).to be_blank

    perform_enqueued_jobs
    invitation_email = ActionMailer::Base.deliveries.last

    expect(invitation_email).to have_attributes(
      subject: "Vous avez été invité sur RDV Service Public",
      from: ["support@rdv-service-public.fr"]
    )
  end

  it "creates a new organisation with tags" do
    login_as(super_admin, scope: :super_admin)
    visit super_admins_root_url(host: "http://www.rdv-service-public-test.localhost")

    click_link "Ouverture de compte"

    fill_in("Nom de l'espace", with: "Mairie de Romainville")
    select("Commune", from: "Catégorie de l'espace")

    # Sélectionner les tags via select2
    find(".field-unit--has-many .select2-selection").click
    find(".select2-results__option", text: "France Services").click
    find(".field-unit--has-many .select2-selection").click
    find(".select2-results__option", text: "France Titres").click

    fill_in("Nom de la première organisation", with: "France Services de Romainville")
    fill_in("Adresse du premier lieu", with: "Place de la mairie, Romainville, 93230")

    # Fake autocomplete
    page.execute_script("document.querySelector('#compte_lieu_latitude').value = '48.880505'")
    page.execute_script("document.querySelector('#compte_lieu_longitude').value = '2.429639'")

    fill_in("Numéro du département", with: "93")

    fill_in("Prénom", with: "Francis")
    fill_in(:compte_agent_last_name, with: "Factice")
    fill_in("Adresse mail", with: "francis@factice.org")

    click_button("Enregistrer")
    expect(page).to have_content("Le nouvel espace a été créé, et une invitation a été envoyée à francis@factice.org")

    new_territory = Territory.last
    expect(new_territory.tags).to contain_exactly(tag_france_services, tag_france_titres)
  end

  describe "ouverture de compte pour une mairie" do
    let!(:cni_motif_category) { create(:motif_category, name: Api::Ants::EditorController::CNI_MOTIF_CATEGORY_NAME) }
    let!(:passport_motif_category) { create(:motif_category, name: Api::Ants::EditorController::PASSPORT_MOTIF_CATEGORY_NAME) }
    let!(:cni_passport_motif_category) { create(:motif_category, name: Api::Ants::EditorController::CNI_AND_PASSPORT_MOTIF_CATEGORY_NAME) }

    it "crée un espace avec une organisation qui a les catégories de motif pour se brancher à l'ANTS" do
      login_as(super_admin, scope: :super_admin)
      visit super_admins_root_url(host: "http://www.rdv-service-public-test.localhost")

      click_link "Ouverture de compte"

      fill_in("Nom de l'espace", with: "Romainville")
      select("Commune", from: "Catégorie de l'espace")
      fill_in("Nom de la première organisation", with: "Mairie de Romainville")
      fill_in("Adresse du premier lieu", with: "Place de la mairie, Romainville, 93230")

      # Fake autocomplete
      page.execute_script("document.querySelector('#compte_lieu_latitude').value = '48.880505'")
      page.execute_script("document.querySelector('#compte_lieu_longitude').value = '2.429639'")

      fill_in("Numéro du département", with: "93")

      expect(page).to have_content("Admin d'espace")

      fill_in("Prénom", with: "Francis")
      fill_in(:compte_agent_last_name, with: "Factice") # Plusieurs champs ont le label "Nom", donc on utilise le name de l'input
      fill_in("Adresse mail", with: "francis@factice.org")

      find(:label, text: "Autoriser le branchement au moteur de recherche de l'ANTS").click

      click_button("Enregistrer")

      expect(page).to have_content("Le nouvel espace a été créé, et une invitation a été envoyée à francis@factice.org")

      mairie_organisation = Organisation.last
      expect(mairie_organisation).to have_attributes(
        ants_connectable: true
      )

      expect(mairie_organisation.motifs.requires_ants_predemande_number.count).to eq(3)
      expect(mairie_organisation.motifs.count).to eq 3

      expect(mairie_organisation.territory.motif_categories.pluck(:name)).to match_array(Api::Ants::EditorController::ANTS_MOTIF_CATEGORY_NAMES)
    end
  end
end
