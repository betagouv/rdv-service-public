RSpec.describe "Agent can accept invitation" do
  let(:agent) { create(:agent) }

  context "avec ProConnect" do
    stub_env_with(
      PRO_CONNECT_BASE_URL: "https://fca.integ01.dev-agentconnect.fr/api/v2",
      PRO_CONNECT_RDVS_CLIENT_SECRET: "un faux secret de test",
      PRO_CONNECT_RDVS_CLIENT_ID: "ec41582-1d60-4f11-a63b-d8abaece16aa"
    )

    it "renseigne le login_hint pour que l'agent utilise ProConnect avec le bon email et évite de rester bloqué" do
      agent.deliver_invitation
      visit accept_agent_invitation_path(invitation_token: agent.raw_invitation_token)
      expect(page).to have_content "connectez-vous avec ProConnect"
      find(".fr-connect__brand").click
      begin
        click_button("S’identifier avec ProConnect")
      rescue ActionController::RoutingError
        # Capybara essaye de suivre une redirection vers "https://fca.integ01.dev-agentconnect.fr/api/v2/authorize
        # ce qui n'est pas possible dans l'env de test (il ignore le host et il cherche /api/v2/authorize dans nos routes).
      end

      redirect_url_query_params = Rack::Utils.parse_query(URI.parse(page.current_url).query)

      expect(redirect_url_query_params["login_hint"]).to eq agent.email
    end

    context "quand l'agent est invité en tant qu'admin" do
      let(:agent) { create(:agent, admin_role_in_organisations: [create(:organisation)]) }

      it "ne propose pas de formulaire de création de compte par mot de passe" do
        agent.deliver_invitation
        visit accept_agent_invitation_path(invitation_token: agent.raw_invitation_token)

        expect(page).to have_no_field "Prénom"
        expect(page).to have_no_button "Créer un compte avec un mot de passe"
      end

      it "rejette une soumission directe de la mise à jour de l'invitation avec un mot de passe" do
        agent.deliver_invitation

        expect do
          page.driver.submit(:put, agent_invitation_path,
                             agent: { first_name: "John", last_name: "Doe", password: "c0rrecThorse!" },
                             invitation_token: agent.raw_invitation_token)
        end.to raise_error(Pundit::NotAuthorizedError)
      end
    end

    context "quand l'agent est invité avec un rôle basique", js: true do
      let(:agent) { create(:agent, basic_role_in_organisations: [create(:organisation)]) }

      it "cache le formulaire de mot de passe derrière un élément repliable et le révèle au clic" do
        agent.deliver_invitation
        visit accept_agent_invitation_path(invitation_token: agent.raw_invitation_token)

        # Le formulaire de mot de passe est caché initialement
        expect(page).to have_content "Vous ne parvenez pas à utiliser ProConnect ?"
        expect(page).to have_no_field "Prénom"

        # Au clic sur le bouton, le formulaire apparaît
        click_button "Créer un compte avec un mot de passe"
        expect(page).to have_field "Prénom"

        # Le texte et bouton d'invitation au collapse disparaissent
        expect(page).to have_no_content "Vous ne parvenez pas à utiliser ProConnect ?"
      end
    end
  end

  context "quand le mot de passe est sécurisé" do
    it "accepte l'invitation" do
      agent.deliver_invitation
      visit accept_agent_invitation_path(invitation_token: agent.raw_invitation_token)
      fill_in "Prénom", with: "John"
      fill_in "Nom", with: "Doe"
      fill_in "Mot de passe", with: "c0rrecThorse!"

      expect { click_on "Enregistrer" }.to change { agent.reload.encrypted_password }
      expect(page).to have_content("Votre mot de passe a été enregistré et votre compte est activé.")
    end
  end

  context "quand le mot de passe n'est pas sécurisé" do
    it "affiche un avertissement et invite à changer le mot de passe" do
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
