RSpec.describe "users pages", :js do
  describe "users_rdvs_path page" do
    it "without RDV is accessible" do
      user = create(:user, email: "toto@example.com")
      login_as(user, scope: :user)
      expect_page_to_be_axe_clean(users_rdvs_path)
    end

    it "with RDV is accessible" do
      user = create(:user, email: "toto@example.com")
      create_list(:rdv, 3, users: [user])
      login_as(user, scope: :user)
      expect_page_to_be_axe_clean(users_rdvs_path)
    end
  end

  it "users_informations_path is accessible" do
    user = create(:user, email: "toto@example.com")
    login_as(user, scope: :user)
    expect_page_to_be_axe_clean(users_informations_path)
  end

  it "users_pending_registration_path is accessible" do
    expect_page_to_be_axe_clean(users_pending_registration_path)
  end

  it "edit_relative_path is accessible" do
    user = create(:user)
    login_as(user, scope: :user)
    expect_page_to_be_axe_clean(edit_relative_path(user))
  end

  it "edit_user_path is accessible" do
    user = create(:user)
    login_as(user, scope: :user)
    expect_page_to_be_axe_clean(edit_user_registration_path)
  end

  it "new_user_session_path is accessible" do
    expect_page_to_be_axe_clean(new_user_session_path)
  end

  it "new_user_password_path is accessible" do
    expect_page_to_be_axe_clean(new_user_password_path)
  end

  it "new_user_registration_path is accessible" do
    expect_page_to_be_axe_clean(new_user_registration_path)
  end
end
