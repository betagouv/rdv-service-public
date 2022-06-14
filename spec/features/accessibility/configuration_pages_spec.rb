# frozen_string_literal: true

describe "configuration pages", js: true do
  it "index of configuration" do
    territory = create(:territory)
    agent = create(:agent, role_in_territories: [territory])
    login_as agent

    path = admin_territory_path(territory)
    expect_page_to_be_axe_clean(path)
  end
end
