# frozen_string_literal: true

describe "Agent can CRUD intervenants" do
  let(:organisation) { create(:organisation) }
  let!(:service) { create(:service, name: "CDAD") }
  let!(:agent_admin) { create(:agent, service: service, admin_role_in_organisations: [organisation]) }
  let!(:agent_intervenant1) { create(:agent, :intervenant, last_name: "intervenant1", organisations: [organisation]) }
  let!(:agent_intervenant2) { create(:agent, :intervenant, last_name: "intervenant2", organisations: [organisation]) }

  before do
    login_as(agent_admin, scope: :agent)
    visit authenticated_agent_root_path
  end

  it "Change intervenant to admin (update agent_role)", js: true do
    visit admin_organisation_agents_path(organisation)
    expect_page_title("Agents de Organisation n°1")

    click_link "INTERVENANT1"
    expect_page_title("Modifier le niveau de permission de l'agent INTERVENANT1")
    choose :agent_role_access_level_admin
    fill_in "Email", with: "ancien_intervenant1@invitation.com"
    click_button("Enregistrer")

    expect_page_title("Invitations en cours pour Organisation n°1")
    expect(page).to have_content("ancien_intervenant1@invitation.com")
    # last_name and first_name are reset when an intervenant is changed to agent
    expect(page).to have_no_content("INTERVENANT1")
  end

  it "Create intervenant" do
    visit admin_organisation_agents_path(organisation)
    expect_page_title("Agents de Organisation n°1")
    click_link "Créer un intervenant"
    expect_page_title("Créer un intervenant pour Organisation n°1")
    fill_in "Nom", with: "Avocat 1"
    click_button("Créer l'intervenant")
    expect_page_title("Agents de Organisation n°1")
    expect(page).to have_content("AVOCAT 1")
  end

  it "Update intervenant last_name" do
    visit admin_organisation_agents_path(organisation)
    expect_page_title("Agents de Organisation n°1")
    click_link "INTERVENANT1"
    expect_page_title("Modifier le niveau de permission de l'agent INTERVENANT1")
    fill_in "Nom", with: "Nouveau nom"
    click_button("Modifier le nom")
    expect_page_title("Agents de Organisation n°1")
    expect(page).to have_content("NOUVEAU NOM")
  end

  it "Delete intervenant" do
    visit admin_organisation_agents_path(organisation)
    expect_page_title("Agents de Organisation n°1")
    click_link "INTERVENANT1"
    expect_page_title("Modifier le niveau de permission de l'agent INTERVENANT1")
    click_link("Supprimer le compte")
    expect_page_title("Agents de Organisation n°1")
    expect(page).to have_no_content("INTERVENANT1")
  end

  it "See intervenant and agents in the dropdown", js: true do
    find("span", text: agent_admin.reverse_full_name, match: :first).click
    expect(page).to have_content(agent_admin.reverse_full_name)
    expect(page).to have_content("INTERVENANT1")
    expect(page).to have_content("INTERVENANT2")
  end
end
