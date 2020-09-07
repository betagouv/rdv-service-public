describe "Agent can update user" do
  let!(:organisation) { create(:organisation) }
  let!(:agent) { create(:agent, organisations: [organisation]) }
  let!(:user) do
    create(:user, first_name: "Jean", last_name: "LEGENDE", email: "jean@legende.com", organisations: [organisation])
  end

  def navigate_to_user_show_page
    login_as(agent, scope: :agent)
    visit authenticated_agent_root_path
    click_link "Vos usagers"
    click_link "Usagers"
    expect_page_title("Vos usagers")
    click_link "Jean LEGENDE"
    expect_page_title("Jean LEGENDE")
  end

  scenario "update existing user's email" do
    navigate_to_user_show_page
    click_link "Modifier"
    fill_in :user_first_name, with: "jeanne"
    fill_in :user_last_name, with: "reynolds"
    fill_in "Email", with: "jeanne@reynolds.com"
    click_button "Modifier"
    # When the user has already a pwd, changing email send a confirmation email
    open_email("jeanne@reynolds.com")
    expect(current_email.subject).to eq I18n.t("devise.mailer.confirmation_instructions.subject")
    expect_page_title("Jeanne REYNOLDS")
    expect(page).to have_content("En attente de confirmation pour jeanne@reynolds.com")
  end

  context "unregistered user" do
    let!(:user) do
      create(:user, :unregistered, first_name: "Jean", last_name: "LEGENDE", email: nil, organisations: [organisation])
    end

    scenario "add email to existing user", js: true do
      navigate_to_user_show_page
      click_link "Modifier"
      fill_in "Email", with: "jean@legende.com"
      click_button "Modifier"
      click_link "Inviter"
      open_email("jean@legende.com")
      expect(current_email.subject).to eq I18n.t("devise.mailer.invitation_instructions.subject")
    end
  end

  it "allows updating user notes from show page" do
    navigate_to_user_show_page
    fill_in :user_user_profiles_attributes_0_notes, with: "Tres cool"
    find(".card#notes input[type=submit]").click
    expect(page).to have_content("L'usager a été modifié")
    expect(page).to have_content("Tres cool")
  end
end
