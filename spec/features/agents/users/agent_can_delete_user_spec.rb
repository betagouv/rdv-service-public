RSpec.describe "Agent can delete user" do
  let!(:organisation) { create(:organisation) }
  let!(:agent) { create(:agent, basic_role_in_organisations: [organisation]) }
  let!(:user) { create(:user, first_name: "Lala", last_name: "LAND", organisations: [organisation]) }

  before do
    login_as(agent, scope: :agent)
    visit admin_organisation_user_path(organisation, user)
  end

  it "delete user", :js do
    click_link("Supprimer")
    page.driver.browser.switch_to.alert.accept
    expect_page_title("Vos usagers")
    expect_page_with_no_record_text("Utilisez le champ de recherche pour trouver un usager")
  end
end
