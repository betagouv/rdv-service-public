RSpec.describe "Agents::ApiTokens", type: :request do
  let(:agent) { create(:agent) }

  before { sign_in agent }

  context "quand le feature flag api_tokens est désactivé" do
    it "renvoie 404 sur toutes les pages" do
      get agents_api_tokens_path
      expect(response).to have_http_status(:not_found)

      get new_agents_api_token_path
      expect(response).to have_http_status(:not_found)
    end
  end

  context "quand le feature flag api_tokens est activé" do
    before { agent.enable_feature!("api_tokens") }

    describe "GET /agents/api_tokens" do
      it "liste uniquement les clés de l'agent connecté" do
        create(:api_token, agent:, name: "Ma clé")
        create(:api_token, name: "Clé d'un autre agent")

        get agents_api_tokens_path

        expect(response).to have_http_status(:success)
        expect(response.body).to include("Ma clé")
        expect(response.body).not_to include("Clé d'un autre agent")
      end
    end

    describe "POST /agents/api_tokens" do
      before { allow(AgentTwoFactorSessionState).to receive(:recent_2fa?).and_return(true) }

      it "crée une clé avec la durée choisie et affiche le token en clair une seule fois dans le flash" do
        expect do
          post agents_api_tokens_path, params: { api_token: { name: "Cron prod", duration: 7.days.to_i } }
        end.to change(ApiToken, :count).by(1)

        api_token = ApiToken.last
        expect(api_token.agent).to eq(agent)
        expect(api_token.expires_at).to be_within(5.seconds).of(7.days.from_now)
        expect(response).to redirect_to(agents_api_tokens_path)
        expect(flash[:raw_api_token]["token"]).to start_with("rdvsp_pat_")
        expect(api_token.token_digest).to eq(ApiToken.digest(flash[:raw_api_token]["token"]))
      end

      it "redirige vers la vérification 2FA si la session n'a pas de 2FA récente" do
        allow(AgentTwoFactorSessionState).to receive(:recent_2fa?).and_return(false)

        expect do
          post agents_api_tokens_path, params: { api_token: { name: "Cron prod", duration: 7.days.to_i } }
        end.not_to change(ApiToken, :count)

        expect(response).to redirect_to(new_agents_two_factor_verification_path)
      end

      it "renvoie 422 si le nom est vide" do
        post agents_api_tokens_path, params: { api_token: { name: "", duration: 7.days.to_i } }

        expect(response).to have_http_status(422)
      end

      it "renvoie 422 si la durée n'est pas une durée proposée" do
        expect do
          post agents_api_tokens_path, params: { api_token: { name: "Cron prod", duration: 999.years.to_i } }
        end.not_to change(ApiToken, :count)

        expect(response).to have_http_status(422)
      end
    end

    describe "DELETE /agents/api_tokens/:id" do
      let!(:api_token) { create(:api_token, agent:) }

      before { allow(AgentTwoFactorSessionState).to receive(:recent_2fa?).and_return(true) }

      it "révoque la clé" do
        delete agents_api_token_path(api_token)

        expect(response).to redirect_to(agents_api_tokens_path)
        expect(api_token.reload).not_to be_accessible
      end

      it "refuse de révoquer la clé d'un autre agent" do
        other_token = create(:api_token)

        delete agents_api_token_path(other_token)

        expect(other_token.reload).to be_accessible
      end
    end
  end
end
