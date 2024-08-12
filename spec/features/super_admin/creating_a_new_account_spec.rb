RSpec.describe "Creating a new account for a new project, other than a mairie", :js do
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
    visit super_admins_root_url(host: "http://www.rdv-mairie-test.localhost")

    click_link "Comptes"
    click_link "Création compte"

    fill_in("Nom du territoire", with: "France Rénov")
    fill_in("Nom de la première organisation", with: "Agence de Romainville")
    fill_in("Adresse du premier lieu", with: "Place de la mairie, Romainville, 93230")

    # Fake autocomplete
    page.execute_script("document.querySelector('#compte_lieu_latitude').value = '48.880505'")
    page.execute_script("document.querySelector('#compte_lieu_longitude').value = '2.429639'")

    fill_in("Numéro du département", with: "FR")

    expect(page).to have_content("Admin de territoire")

    fill_in("Prénom", with: "Francis")
    fill_in(:compte_agent_last_name, with: "Factice") # Plusieurs champs ont le label "Nom", donc on utilise le name de l'input
    fill_in("Adresse mail", with: "francis@factice.org")
    select("Urbanisme", from: "Service")

    click_button("Enregistrer")
    expect(page).to have_content("Le nouveau compte a été créé, et une invitation a été envoyée à francis@factice.org")

    expect(page).to have_content("Francis FACTICE")
    expect(Organisation.count).to eq(1)

    new_territory = Territory.last
    expect(new_territory).to have_attributes(
      name: "France Rénov"
    )

    new_agent = new_territory.admin_agents.first

    expect(new_territory.services).to eq new_agent.services

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

    new_motif = new_organisation.motifs.first
    expect(new_motif).to have_attributes(
      name: "Mon premier motif"
    )

    perform_enqueued_jobs
    invitation_email = ActionMailer::Base.deliveries.last

    expect(invitation_email).to have_attributes(
      subject: "Vous avez été invité sur RDV Service Public",
      from: ["support@rdv-service-public.fr"]
    )
  end
end
