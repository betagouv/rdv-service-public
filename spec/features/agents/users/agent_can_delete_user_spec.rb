describe "Agent can delete user" do
  let!(:organisation) { create(:organisation) }
  let!(:agent) { create(:agent, organisations: [organisation]) }
  let!(:user) { create(:user, first_name: "Lala", last_name: "LAND", organisations: [organisation]) }

  before do
    login_as(agent, scope: :agent)
    visit authenticated_agent_root_path
    click_link "Vos usagers"
    click_link "Lala LAND"
  end

  scenario "delete user", js: true do
    click_link("Supprimer")
    page.driver.browser.switch_to.alert.accept
    expect_page_title("Vos usagers")
    expect_page_with_no_record_text("Vous n'avez pas encore ajouté d'usager.")
  end
end
