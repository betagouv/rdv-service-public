RSpec.describe "Un agent basique peut voir la configuration de l'organisation" do
  let!(:organisation) { create(:organisation, name: "MDS Montreuil Nord") }
  let!(:agent_admin) { create(:agent, last_name: "Zorro", first_name: "Don", admin_role_in_organisations: [organisation]) }
  let!(:agent_basic) { create(:agent, last_name: "Aaron", first_name: "Anna", basic_role_in_organisations: [organisation]) }
  let!(:lieu) { create(:lieu, organisation: organisation) }

  specify do
    login_as(agent_basic, scope: :agent)

    visit authenticated_agent_root_path
    click_link "Configuration"
    expect_page_title("Configuration")

    expect(page).to have_link("Motifs de rendez-vous")
    expect(page).to have_link("Lieux")
    expect(page).to have_link("Agents")
    expect(page).to have_link("Réservation en ligne")
    expect(page).not_to have_link("Informations de l'organisation")

    click_link "Agents"
    expect_page_title("Agents")

    within("tr", text: agent_admin.last_name.upcase) do
      expect(page).to have_content(agent_admin.email)
      expect(page).to have_content("Administrateur")
    end

    within("tr", text: agent_admin.last_name.upcase) do
      expect(page).not_to have_link("Modifier")
      expect(page).not_to have_link("Supprimer")
    end
    expect(page).not_to have_link("Ajouter un agent")
  end
end
