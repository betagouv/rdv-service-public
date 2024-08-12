RSpec.describe "Agent can delete a relative" do
  let!(:organisation) { create(:organisation) }
  let!(:agent) { create(:agent, basic_role_in_organisations: [organisation]) }
  let!(:user) do
    create(:user, first_name: "Fiona", last_name: "LEGENDE", email: "jean@legende.com", organisations: [organisation])
  end
  let!(:relative) do
    create(:user, :relative, responsible: user, first_name: "Mimi", last_name: "LEGENDE")
  end

  it "works", :js do
    login_as(agent, scope: :agent)
    visit admin_organisation_user_path(organisation, relative)
    click_link("Supprimer")
    page.driver.browser.switch_to.alert.accept
    expect_page_title "Fiona LEGENDE"
    expect(page).to have_content("L’usager a été supprimé")
    expect(page).to have_content("Aucun proche")
  end
end
