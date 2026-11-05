RSpec.describe "Paramètres de sécurité d'un espace", type: :request do
  let(:territory) { create(:territory) }
  let(:organisation) { create(:organisation, territory:) }
  let!(:territory_admin) { create(:agent, role_in_territories: [territory], admin_role_in_organisations: [organisation]) }
  let!(:basic_agent) { create(:agent, password: "c0rrecThorse!", basic_role_in_organisations: [organisation]) }

  context "quand l'agent est admin de l'espace" do
    before { sign_in territory_admin }

    it "affiche le formulaire" do
      get edit_admin_territory_security_settings_path(territory)

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("territory[force_2fa_for_agents]")
    end

    it "active l'obligation de double authentification et recalcule les agents de l'espace" do
      expect do
        patch admin_territory_security_settings_path(territory), params: { territory: { force_2fa_for_agents: "1" } }
      end.to have_enqueued_job(Territories::RefreshAgentsSensitiveAccountJob).with(territory)

      expect(territory.reload.force_2fa_for_agents).to be true
      expect(response).to redirect_to(edit_admin_territory_security_settings_path(territory))
    end

    it "ne recalcule pas les agents si l'option n'a pas changé" do
      expect do
        patch admin_territory_security_settings_path(territory), params: { territory: { force_2fa_for_agents: "0" } }
      end.not_to have_enqueued_job(Territories::RefreshAgentsSensitiveAccountJob)
    end

    it "impose la double authentification à la prochaine connexion d'un agent de l'espace" do
      perform_enqueued_jobs do
        patch admin_territory_security_settings_path(territory), params: { territory: { force_2fa_for_agents: "1" } }
      end
      expect(basic_agent.reload.sensitive_account).to be true

      delete destroy_agent_session_path
      post agent_session_path, params: { agent: { email: basic_agent.email, password: "c0rrecThorse!" } }

      expect(response).to redirect_to(new_agents_sign_in_code_verification_path)
    end

    it "lève l'obligation quand l'option est désactivée" do
      territory.update!(force_2fa_for_agents: true)
      basic_agent.update!(sensitive_account: true)

      perform_enqueued_jobs do
        patch admin_territory_security_settings_path(territory), params: { territory: { force_2fa_for_agents: "0" } }
      end

      expect(basic_agent.reload.sensitive_account).to be false
    end
  end

  context "quand l'agent n'est pas admin de l'espace" do
    let(:organisation_admin) { create(:agent, admin_role_in_organisations: [organisation]) }

    before { sign_in organisation_admin }

    it "ne permet pas de modifier l'option" do
      patch admin_territory_security_settings_path(territory), params: { territory: { force_2fa_for_agents: "1" } }

      expect(territory.reload.force_2fa_for_agents).to be false
    end
  end
end
