# frozen_string_literal: true

describe "users pages", js: true do
  it "accessibility_path page is accessible" do
    expect_page_to_be_axe_clean(accessibility_path)
  end

  it "users_rdvs_path page is accessible" do
    user = create(:user, email: "toto@example.com")
    login_as user
    expect_page_to_be_axe_clean(users_rdvs_path)
  end

  it "users_informations_path is accessible" do
    user = create(:user, email: "toto@example.com")
    login_as user
    expect_page_to_be_axe_clean(users_informations_path)
  end

  it "users_pending_registration_path is accessible" do
    expect_page_to_be_axe_clean(users_pending_registration_path)
  end

  it "new_relative_path is accessible" do
    user = create(:user)
    login_as user
    expect_page_to_be_axe_clean(new_relative_path)
  end

  it "edit_relative_path is accessible" do
    user = create(:user)
    login_as user
    expect_page_to_be_axe_clean(edit_relative_path(user))
  end
end
