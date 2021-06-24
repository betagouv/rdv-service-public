# frozen_string_literal: true

describe "Agent can update user" do
  let!(:organisation) { create(:organisation) }
  let!(:agent) { create(:agent, basic_role_in_organisations: [organisation]) }
  let!(:user) do
    create(:user, first_name: "Jean", last_name: "LEGENDE", email: "jean@legende.com", organisations: [organisation])
  end

  before do
    login_as(agent, scope: :agent)
    visit authenticated_agent_root_path
    click_link "Usagers"
    expect_page_title("Vos usagers")
    click_link "Jean LEGENDE"
    expect_page_title("Jean LEGENDE")
    click_link "Modifier"
  end

  it "update existing user's email" do
    fill_in :user_first_name, with: "jeanne"
    fill_in :user_last_name, with: "reynolds"
    fill_in "Email", with: "jeanne@reynolds.com"
    click_button "Enregistrer"
    # When the user has already a pwd, changing email send a confirmation email
    open_email("jeanne@reynolds.com")
    expect(current_email.subject).to eq I18n.t("devise.mailer.confirmation_instructions.subject")
    expect_page_title("Jeanne REYNOLDS")
    expect(page).to have_content("En attente de confirmation pour jeanne@reynolds.com")
  end

  it "update user notes" do
    fill_in "Remarques", with: "Pas très sympa"
    click_button "Enregistrer"
    expect(page).to have_content("Pas très sympa")
  end

  context "unregistered user" do
    let!(:user) do
      create(:user, :unregistered, first_name: "Jean", last_name: "LEGENDE", email: nil, organisations: [organisation])
    end

    it "add email to existing user", js: true do
      fill_in "Email", with: "jean@legende.com"
      click_button "Enregistrer"
      click_link "Inviter"
      open_email("jean@legende.com")
      expect(current_email.subject).to eq I18n.t("devise.mailer.invitation_instructions.subject")
    end
  end
end
