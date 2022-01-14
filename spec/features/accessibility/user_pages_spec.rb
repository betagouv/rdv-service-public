# frozen_string_literal: true

describe "welcome", js: true do
  it "root path page is accessible" do
    visit root_path
    expect(page).to be_axe_clean
  end

  it "accueil_mds_path page is accessible" do
    visit accueil_mds_path
    expect(page).to be_axe_clean
  end

  it "accessibility_path page is accessible" do
    visit accessibility_path
    expect(page).to be_axe_clean
  end
end
