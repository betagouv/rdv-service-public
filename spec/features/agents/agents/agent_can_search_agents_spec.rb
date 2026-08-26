RSpec.describe "Un agent admin peut filtrer la liste d'agents" do
  let(:organisation) { create(:organisation) }
  let(:admin) { create(:agent, admin_role_in_organisations: [organisation]) }
  let!(:tony) { create(:agent, first_name: "Tony", last_name: "Patrick", basic_role_in_organisations: [organisation]) }
  let!(:other_admin) { create(:agent, first_name: "Ada", last_name: "Minor", admin_role_in_organisations: [organisation]) }
  let!(:other_agents) { create_list(:agent, 3, basic_role_in_organisations: [organisation]) }

  specify "recherche textuelle" do
    login_as(admin, scope: :agent)
    visit admin_organisation_agents_path(organisation)
    expect(page).to have_field(placeholder: "Prénom, Nom, Email")
    fill_in placeholder: "Prénom, Nom, Email", with: "Patrick"
    click_button "Filtrer"
    expect(page).to have_content("PATRICK Tony")
    other_agents.each { |agent| expect(page).to have_no_content(agent.last_name.upcase) }

    click_link "Réinitialiser"
    expect(page).to have_content("PATRICK Tony")
    expect(page).to have_content(other_agents.first.last_name.upcase)
  end

  specify "filtre admin seulement" do
    login_as(admin, scope: :agent)
    visit admin_organisation_agents_path(organisation)
    check "Uniquement les admin"
    click_button "Filtrer"

    expect(page).to have_content("MINOR Ada")
    expect(page).to have_no_content("PATRICK Tony")
    other_agents.each { |agent| expect(page).to have_no_content(agent.last_name.upcase) }
  end
end
