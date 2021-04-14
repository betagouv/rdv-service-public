describe "Agent can delete a relative" do
  let!(:organisation) { create(:organisation) }
  let!(:agent) { create(:agent, basic_role_in_organisations: [organisation]) }
  let!(:user) do
    create(:user, first_name: "Fiona", last_name: "LEGENDE", email: "jean@legende.com", organisations: [organisation])
  end
  let!(:relative) do
    create(:user, :relative, responsible: user, first_name: "Mimi", last_name: "LEGENDE")
  end

  before do
    login_as(agent, scope: :agent)
    visit authenticated_agent_root_path
    click_link "Usagers"
    click_link "Mimi LEGENDE"
  end

  it "works", js: true do
    click_link("Supprimer")
    page.driver.browser.switch_to.alert.accept
    expect_page_title "Fiona LEGENDE"
    expect(page).to have_content("L'usager a été supprimé")
    expect(page).to have_content("Aucun proche")
  end
end
