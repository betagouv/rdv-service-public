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
    visit "http://www.rdv-service-public-test.localhost/"
    expect(page).to have_content("MDS de Paris Nord")
    expect(page).to have_content("MDS de Paris Sud")
  end
end
