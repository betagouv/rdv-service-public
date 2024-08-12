RSpec.describe "configuration pages", :js do
  it "index of configuration" do
    territory = create(:territory)
    agent = create(:agent, role_in_territories: [territory])
    login_as(agent, scope: :agent)

    path = admin_territory_path(territory)
    expect_page_to_be_axe_clean(path)
  end
end
