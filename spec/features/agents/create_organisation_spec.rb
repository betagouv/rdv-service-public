RSpec.describe "Organisations" do
  let!(:territory) { create(:territory) }
  let!(:organisation1) { create(:organisation, territory: territory, name: "MDS de Paris Nord") }
  let!(:organisation2) { create(:organisation, territory: territory, name: "MDS de Paris Sud") }

  let!(:agent) do
    create(
      :agent,
      admin_role_in_organisations: [organisation1, organisation2],
      role_in_territories: [territory]
    )
  end

  before { login_as(agent, scope: :agent) }

  it "shows the list of organisations when an agent with multiple organisations logs in" do
    visit root_path
    expect(page).to have_content("MDS de Paris Nord")
    expect(page).to have_content("MDS de Paris Sud")
    click_link "Ajouter une organisation"

    fill_in "Nom", with: "MDS Paris Est"
    click_button "Enregistrer"
    expect(page).to have_content("Organisation enregistrée")
    expect(Organisation.last).to have_attributes(
      name: "MDS Paris Est",
      territory: territory,
      agents: [agent]
    )
  end
end
