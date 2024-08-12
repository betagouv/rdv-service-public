RSpec.describe "Agent can CRUD intervenants" do
  let(:organisation) { create(:organisation) }
  let!(:service) { create(:service, name: "CDAD", territories: [organisation.territory]) }
  let!(:agent_admin) { create(:agent, service: service, admin_role_in_organisations: [organisation], email: "admin@example.com", first_name: "Francis", last_name: "Admin") }
  let!(:agent_intervenant1) { create(:agent, :intervenant, last_name: "intervenant1", organisations: [organisation]) }
  let!(:agent_intervenant2) { create(:agent, :intervenant, last_name: "intervenant2", organisations: [organisation]) }

  before { login_as(agent_admin, scope: :agent) }

  specify "full intervenant lifecycle", :js do
    visit admin_organisation_agents_path(organisation)
    expect_page_title("Agents de Organisation n°1")

    # Create an intervenant
    click_link "Ajouter un agent", match: :first
    expect_page_title("Ajouter un agent")
    check(service.name)
    find("label", text: "Intervenant").click
    fill_in "Nom", with: "Avocat 1"
    click_button("Enregistrer")
    expect_page_title("Agents de Organisation n°1")
    expect(page).to have_content("AVOCAT 1")
    expect(Agent.last).to have_attributes(
      plage_ouverture_notification_level: "none",
      rdv_notifications_level: "none",
      absence_notification_level: "none"
    )

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
    within(".js_agent_role_form") do
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
      uid: "ancien_intervenant1@invitation.com",
      plage_ouverture_notification_level: "all",
      rdv_notifications_level: "others",
      absence_notification_level: "all"
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

    accept_alert do
      click_button("Enregistrer")
    end

    expect_page_title("Agents de Organisation n°1")

    expect(Agent.last.roles.pluck(:access_level)).to eq ["intervenant"]
    expect(Agent.last).to have_attributes(
      last_name: "Fictif",
      first_name: nil,
      email: nil,
      uid: nil,
      invitation_token: nil,
      invitation_accepted_at: nil,
      invitation_created_at: nil,
      invitation_sent_at: nil,
      invited_by_id: nil,
      invited_by_type: nil,
      plage_ouverture_notification_level: "none",
      rdv_notifications_level: "none",
      absence_notification_level: "none"
    )

    # On vérifie que nos factories correspondent à la réalité
    intervenant_from_factory = create(:agent, :intervenant)
    attributes_from_factory = intervenant_from_factory.attributes.compact.keys.sort
    attributes_from_integration_spec = Agent.last.attributes.compact.keys.sort
    expect(attributes_from_factory).to match_array(attributes_from_integration_spec)

    # Delete the intervenant
    click_link "FICTIF"
    expect_page_title("Modifier le niveau de permission de l'agent FICTIF")
    accept_alert do
      click_link("Supprimer le compte")
    end
    expect_page_title("Agents de Organisation n°1")
    expect(page).to have_no_content("FICTIF")
  end

  describe "validation errors on agent email when turning an intervenant into an agent with account" do
    it "displays errors", :js do
      visit admin_organisation_agents_path(organisation)
      click_link "INTERVENANT1"

      find("label", text: "Basique").click
      fill_in "Email", with: agent_admin.email
      fill_in "Prénom", with: "  "
      within(".js_agent_role_form") do
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
      within(".js_agent_role_form") do
        fill_in "Nom", with: "Fictif", match: :smart
      end
      click_button("Enregistrer")

      expect(agent_intervenant1.reload.roles.pluck(:access_level)).to eq ["basic"]
    end
  end

  it "doesn't allow turning the current agent into an intervenant" do
    visit admin_organisation_agents_path(organisation)
    click_link "ADMIN Francis"
    expect(page).not_to have_content("Intervenant")
  end

  context "when an agent belongs to multiple organisations" do
    let!(:agent_in_multiple_organisations) do
      create(:agent, service: service, basic_role_in_organisations: [organisation], first_name: "Francis", last_name: "Factice")
    end

    let!(:other_role) do
      create(:agent_role, agent: agent_in_multiple_organisations, access_level: :basic)
    end

    it "doesn't allow turning them into an intervenant" do
      # Front end validation
      visit admin_organisation_agents_path(organisation)
      click_link "FACTICE Francis"
      expect(page).not_to have_content("Intervenant")

      # Backend validation
      other_role.delete

      visit current_path
      find("label", text: "Intervenant").click

      create(:agent_role, agent: agent_in_multiple_organisations, access_level: :basic)

      click_button("Enregistrer")

      expect(page).to have_content("Un agent membre de plusieurs organisations ne peut pas avoir un statut d'intervenant")
      expect(agent_in_multiple_organisations.reload.roles.pluck(:access_level)).to eq(%w[basic basic])
    end
  end
end
