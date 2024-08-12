RSpec.describe "Agent can update a RDV", :js do
  let!(:organisation) { create(:organisation) }
  let!(:service) { create(:service) }
  let!(:agent) { create(:agent, first_name: "Alain", last_name: "Tiptop", service: service, basic_role_in_organisations: [organisation]) }

  before do
    stub_netsize_ok
    login_as(agent, scope: :agent)
  end

  it "update existing RDV with single_use lieu" do
    motif = create(:motif, service: service, organisation: organisation)
    lieu = create(:lieu, organisation: organisation)
    rdv = create(:rdv, organisation: organisation, motif: motif, agents: [agent], lieu: lieu)

    visit edit_admin_organisation_rdv_path(organisation, rdv)
    click_link("Définir un lieu ponctuel.")
    fill_in "Nom", with: "Café de la gare"
    fill_in "Adresse", with: "3 Place de la Gare, Strasbourg, 67000"
    page.execute_script("document.querySelector('input#rdv_lieu_attributes_latitude').value = '48.583844'")
    page.execute_script("document.querySelector('input#rdv_lieu_attributes_longitude').value = 7.735253")
    click_button "Enregistrer"

    expect(page).to have_content("Café de la gare")
    expect(page).to have_content("3 Place de la Gare, Strasbourg, 67000")
    expect(page).to have_selector(".badge-info", text: /Ponctuel/)
  end

  it "update existing RDV with existing lieu" do
    motif = create(:motif, service: service, organisation: organisation)
    lieu_ponctuel = create(:lieu, organisation: organisation, availability: :single_use)
    lieu = create(:lieu, organisation: organisation, availability: :enabled)
    rdv = create(:rdv, organisation: organisation, motif: motif, agents: [agent], lieu: lieu_ponctuel)

    visit edit_admin_organisation_rdv_path(organisation, rdv)

    click_link("Choisir un lieu existant.")
    select(lieu.full_name, from: "rdv_lieu_id")
    click_button "Enregistrer"

    expect(page).to have_content(lieu.full_name)
    expect(page).not_to have_selector(".badge-info", text: /Ponctuel/)
  end
end
