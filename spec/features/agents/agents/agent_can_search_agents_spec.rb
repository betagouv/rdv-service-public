RSpec.describe "Un agent peut chercher des agents dans la liste" do
  let(:organisation) { create(:organisation) }
  let(:organisation_admin) { create(:agent, admin_role_in_organisations: [organisation]) }
  let!(:tony) { create(:agent, first_name: "Tony", last_name: "Patrick", basic_role_in_organisations: [organisation]) }
  let!(:other_agents) { create_list(:agent, 10, basic_role_in_organisations: [organisation]) }

  specify do
    login_as(organisation_admin, scope: :agent)
    visit admin_organisation_agents_path(organisation)
    expect(page).to have_field(placeholder: "Prénom, Nom, Email")
    fill_in placeholder: "Prénom, Nom, Email", with: "Patrick"
    click_button "Rechercher"
    expect(page).to have_content("PATRICK Tony")
    other_agents.each { |agent| expect(page).to have_no_content(agent.last_name.upcase) }

    click_link "Réinitialiser"
    expect(page).to have_content("PATRICK Tony")
    expect(page).to have_content(other_agents.first.last_name.upcase)
  end
end
