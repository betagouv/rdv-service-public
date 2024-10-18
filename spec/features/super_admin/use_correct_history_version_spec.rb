RSpec.describe "Use correct history version when a super admin is logged in and use impersonate", versioning: true do
  let!(:organisation) { create(:organisation) }
  let!(:service) { create(:service) }
  let!(:agent) { create(:agent, admin_role_in_organisations: [organisation], service: service) }
  let!(:user) { create(:user, organisations: [organisation]) }
  let!(:super_admin) { create(:super_admin) }

  before do
    login_as(super_admin, scope: :super_admin)
  end

  it "for an agent", js: true do
    login_as(agent, scope: :agent)
    visit admin_organisation_user_path(organisation, user)
    within("#spec-primary-user-card") { click_link "Modifier" }
    fill_in :user_first_name, with: "jeanne d'arc"
    click_button "Enregistrer"

    click_button("Historique des changements")
    expect(page).to have_content("[Admin] #{super_admin.full_name} pour #{agent.full_name}")
  end

  it "for a user", js: true do
    login_as(user, scope: :user)
    visit root_path
    click_link "Vos informations"
    fill_in("Téléphone", with: "0612345678")
    click_on("Modifier")

    expect(user.reload.versions.last.whodunnit).to eq "[Admin] #{super_admin.full_name} pour #{user.full_name}"
  end
end
