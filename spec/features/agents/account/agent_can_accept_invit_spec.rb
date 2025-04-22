RSpec.describe "Agent can accept invitation" do
  let(:agent) { create(:agent) }

  context "when using ProConnect" do
    stub_env_with(
      AGENT_CONNECT_BASE_URL: "https://fca.integ01.dev-agentconnect.fr/api/v2",
      AGENT_CONNECT_RDVSP_CLIENT_SECRET: "un faux secret de test",
      AGENT_CONNECT_RDVSP_CLIENT_ID: "ec41582-1d60-4f11-a63b-d8abaece16aa"
    )

    it "sets the login_hint to make sure the agent uses ProConnect with the right email and avoids getting stuck" do
      agent.deliver_invitation
      visit accept_agent_invitation_path(invitation_token: agent.raw_invitation_token)
      expect(page).to have_content "Se créer un compte avec ProConnect"
      find(".fr-connect__brand").click
      begin
        click_button("ProConnect")
      rescue ActionController::RoutingError
        # Capybara essaye de suivre une redirection vers "https://fca.integ01.dev-agentconnect.fr/api/v2/authorize
        # ce qui n'est pas possible dans l'env de test (il ignore le host et il cherche /api/v2/authorize dans nos routes).
      end

      redirect_url_query_params = Rack::Utils.parse_query(URI.parse(page.current_url).query)

      expect(redirect_url_query_params["login_hint"]).to eq agent.email
    end
  end

  context "when password is secure" do
    it "accepts the invitation" do
      agent.deliver_invitation
      visit accept_agent_invitation_path(invitation_token: agent.raw_invitation_token)
      fill_in "Prénom", with: "John"
      fill_in "Nom", with: "Doe"
      fill_in "Mot de passe", with: "c0rrecThorse!"

      expect { click_on "Enregistrer" }.to change { agent.reload.encrypted_password }
      expect(page).to have_content("Votre mot de passe a été enregistré et votre compte est activé.")
    end
  end

  context "when password is not secure" do
    it "shows a warning and advises to change the password" do
      agent.deliver_invitation
      visit accept_agent_invitation_path(invitation_token: agent.raw_invitation_token)
      fill_in "Prénom", with: "John"
      fill_in "Nom", with: "Doe"
      fill_in "Mot de passe", with: "tropfaible"

      click_on "Enregistrer"
      expect(page).to have_content("Pour assurer la sécurité de votre compte, votre mot de passe doit faire au moins 12 caractères")
    end
  end
end
