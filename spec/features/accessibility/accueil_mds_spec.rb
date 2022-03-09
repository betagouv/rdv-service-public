# frozen_string_literal: true

describe "accueil_mds", js: true do
  it "root path page is accessible" do
    expect_page_to_be_axe_clean(accueil_mds_path)
  end
  it "agent agenda path page is accessible" do
    expect_page_to_be_axe_clean(admin_organisation_agent_agenda_path)
  end
end
