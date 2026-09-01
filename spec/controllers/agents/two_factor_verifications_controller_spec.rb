RSpec.describe Agents::TwoFactorVerificationsController, type: :controller do
  let(:agent) { create(:agent) }

  before { sign_in agent }

  describe "#new" do
    context "quand l'agent n'a pas la double authentification ProConnect active" do
      it "envoie un code de vérification par email et affiche le formulaire" do
        expect { get :new }
          .to change(LoginCode, :count).by(1)
          .and have_enqueued_mail(Agents::LoginCodeMailer, :login_code)
        expect(LoginCode.last.email).to eq(agent.email)
        expect(response).to have_http_status(:ok)
      end
    end

    context "quand l'agent a la double authentification ProConnect active" do
      stub_env_for_proconnect

      let(:agent) { create(:agent, pro_connect_2fa_active: true) }

      it "redirige vers ProConnect en exigeant le 2FA" do
        get :new

        expect(response).to redirect_to(start_with("https://fca.integ01.dev-agentconnect.fr/api/v2/authorize?"))
        redirect_url_query_params = Rack::Utils.parse_query(URI.parse(response.headers["Location"]).query)
        expect(redirect_url_query_params.symbolize_keys).to include(
          login_hint: agent.email,
          claims: {
            id_token: {
              acr: {
                essential: true,
                values: %w[eidas0-mfa eidas1-mfa eidas2 eidas3],
              },
            },
          }.to_json
        )
        expect(session["pro_connect"][:connection_for]).to eq("agent_step_up")
      end
    end
  end

  describe "#resend" do
    it "envoie un nouveau code par email et redirige vers le formulaire" do
      expect { post :resend }
        .to change(LoginCode, :count).by(1)
        .and have_enqueued_mail(Agents::LoginCodeMailer, :login_code)
      expect(response).to redirect_to(new_agents_two_factor_verification_path)
    end
  end

  describe "#create" do
    let!(:login_code) { create(:login_code, email: agent.email) }

    context "avec un code valide" do
      it "marque la double authentification comme vérifiée et redirige vers la page demandée" do
        session[:two_factor_step_up_return_to] = "/agents/exports/42/download"

        post :create, params: { login_code: { code: login_code.code } }

        expect(session[:agent_2fa_verified_at]).to be_present
        expect(response).to redirect_to("/agents/exports/42/download")
        expect(session[:two_factor_step_up_return_to]).to be_nil
      end

      it "marque le code comme utilisé" do
        post :create, params: { login_code: { code: login_code.code } }
        expect(login_code.reload.used_at).to be_present
      end

      it "redirige vers la page des exports quand aucune page de retour n'est mémorisée" do
        post :create, params: { login_code: { code: login_code.code } }
        expect(response).to redirect_to(agents_exports_path)
      end
    end

    context "avec un code invalide" do
      it "ne marque pas la double authentification comme vérifiée" do
        post :create, params: { login_code: { code: "000000" } }
        expect(session[:agent_2fa_verified_at]).to be_nil
      end

      it "réaffiche le formulaire" do
        post :create, params: { login_code: { code: "000000" } }
        expect(response).to render_template(:new)
      end
    end
  end
end
