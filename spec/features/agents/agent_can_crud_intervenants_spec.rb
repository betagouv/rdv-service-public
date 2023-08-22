# frozen_string_literal: true

describe "Agent can CRUD intervenants" do
  let(:organisation) { create(:organisation) }
  let!(:service) { create(:service, name: "CDAD") }
  let!(:agent_admin) { create(:agent, service: service, admin_role_in_organisations: [organisation], email: "admin@example.com") }
  let!(:agent_intervenant1) { create(:agent, :intervenant, last_name: "intervenant1", organisations: [organisation]) }
  let!(:agent_intervenant2) { create(:agent, :intervenant, last_name: "intervenant2", organisations: [organisation]) }

  before { login_as(agent_admin, scope: :agent) }

  specify "full intervenant lifecycle", js: true do
    visit admin_organisation_agents_path(organisation)
    expect_page_title("Agents de Organisation n°1")

    # Create an intervenant
    click_link "Ajouter un agent", match: :first
    expect_page_title("Ajouter un agent")
    find("label", text: "Intervenant").click
    fill_in "Nom", with: "Avocat 1"
    click_button("Ajouter l'intervenant")
    expect_page_title("Agents de Organisation n°1")
    expect(page).to have_content("AVOCAT 1")

    # Change their last name
    click_link "INTERVENANT1"
    expect_page_title("Modifier le niveau de permission de l'agent INTERVENANT1")
    fill_in "Nom", with: "Nouveau nom"
    click_button("Modifier le nom")
    expect_page_title("Agents de Organisation n°1")
    expect(page).to have_content("AVOCAT 1")

    # Change the intervenant into an admin agent
    click_link "AVOCAT 1"
    expect_page_title("Modifier le niveau de permission de l'agent AVOCAT 1")
    find("label", text: "Administrateur").click
    fill_in "Email", with: "ancien_intervenant1@invitation.com"
    fill_in "Prénom", with: "Bob"
    within(".js_agent_form") do
      fill_in "Nom", with: "Fictif", match: :smart
    end
    click_button("Enregistrer")

    expect(Agent.last.roles.pluck(:access_level)).to eq ["admin"]

    expect { perform_enqueued_jobs }.not_to raise_error
    expect(ActionMailer::Base.deliveries.size).to eq(1)
    expect(ActionMailer::Base.deliveries.last.subject).to eq("Vous avez été invité sur RDV Solidarités")
    expect(ActionMailer::Base.deliveries.last.to).to eq(["ancien_intervenant1@invitation.com"])

    expect(Agent.last).to have_attributes(
      email: "ancien_intervenant1@invitation.com",
      uid: "ancien_intervenant1@invitation.com"
    )

    expect_page_title("Invitations en cours pour Organisation n°1")
    expect(page).to have_content("ancien_intervenant1@invitation.com")
    expect(page).to have_content("FICTIF Bob")

    # Verify the agent name display
    visit authenticated_agent_root_path
    find("span", text: agent_admin.reverse_full_name, match: :first).click
    expect(page).to have_content(agent_admin.reverse_full_name)
    expect(page).to have_content("FICTIF Bob")
    expect(page).to have_content("INTERVENANT2")

    # Change the agent back into an intervenant
    visit admin_organisation_invitations_path(organisation)
    click_link "FICTIF Bob"
    find("label", text: "Intervenant").click
    click_button("Enregistrer")

    expect(Agent.last.roles.pluck(:access_level)).to eq ["intervenant"]
    expect(Agent.last).to have_attributes(
      last_name: "Fictif",
      first_name: nil
    )

    # Delete the intervenant
    expect_page_title("Agents de Organisation n°1")
    click_link "FICTIF"
    expect_page_title("Modifier le niveau de permission de l'agent FICTIF")
    accept_alert do
      click_link("Supprimer le compte")
    end
    expect_page_title("Agents de Organisation n°1")
    expect(page).to have_no_content("FICTIF")
  end

  describe "validation errors on agent email when turning an intervenant into an agent with account" do
    it "displays errors", js: true do
      visit admin_organisation_agents_path(organisation)
      click_link "INTERVENANT1"

      find("label", text: "Basique").click
      fill_in "Email", with: agent_admin.email
      fill_in "Prénom", with: "  "
      within(".js_agent_form") do
        fill_in "Nom", with: "  ", match: :smart
      end
      click_button("Enregistrer")

      expect(page).to have_content("Email est déjà utilisé")
      expect(page).to have_content("Prénom doit être rempli(e)")
      expect(page).to have_content("Nom d’usage doit être rempli(e)")

      expect(enqueued_jobs).to be_empty

      expect(agent_intervenant1.reload.roles.pluck(:access_level)).to eq ["intervenant"]
      expect(agent_intervenant1).to have_attributes(first_name: nil, last_name: "intervenant1", email: nil)

      fill_in "Email", with: "nouvel_agent@exemple.fr"
      fill_in "Prénom", with: "Bob"
      within(".js_agent_form") do
        fill_in "Nom", with: "Fictif", match: :smart
      end
      click_button("Enregistrer")

      expect(agent_intervenant1.reload.roles.pluck(:access_level)).to eq ["basic"]
    end
  end
end
