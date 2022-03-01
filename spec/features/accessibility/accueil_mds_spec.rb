# frozen_string_literal: true

describe "accueil_mds", js: true do
  it "root path page is accessible" do
    expect_page_to_be_axe_clean(accueil_mds_path)
  end
end
