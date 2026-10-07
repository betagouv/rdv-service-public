RSpec.describe Agents::TwoFactorVerificationsController, type: :controller do
  let(:agent) { create(:agent) }

  before { sign_in agent }

  describe "#new" do
    render_views

    it "affiche la page d'explication sans envoyer de code" do
      expect { get :new }.not_to change(LoginCode, :count)
      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Recevoir un code par email")
    end

    context "quand l'agent a la double authentification ProConnect active" do
      let(:agent) { create(:agent, pro_connect_2fa_active: true) }

      it "propose de continuer vers ProConnect" do
        get :new
        expect(response.body).to include("Continuer vers ProConnect")
      end
    end
  end

  describe "#create" do
    context "quand l'agent n'a pas la double authentification ProConnect active" do
      it "envoie un code de vérification par email et redirige vers le formulaire de saisie" do
        expect { post :create }
          .to change(LoginCode, :count).by(1)
          .and have_enqueued_mail(Agents::LoginCodeMailer, :login_code)
        expect(LoginCode.last.email).to eq(agent.email)
        expect(response).to redirect_to(code_agents_two_factor_verification_path)
      end
    end

    context "quand l'agent a la double authentification ProConnect active" do
      stub_env_for_proconnect

      let(:agent) { create(:agent, pro_connect_2fa_active: true) }

      it "redirige vers ProConnect en exigeant le 2FA" do
        expect { post :create }.not_to change(LoginCode, :count)

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

  describe "#code" do
    context "quand un code a déjà été envoyé" do
      before { create(:login_code, email: agent.email) }

      it "affiche le formulaire sans envoyer de nouveau code" do
        expect { get :code }.not_to change(LoginCode, :count)
        expect(response).to have_http_status(:ok)
      end
    end

    context "quand aucun code n'a été envoyé" do
      it "redirige vers la page d'explication" do
        get :code
        expect(response).to redirect_to(new_agents_two_factor_verification_path)
      end
    end
  end

  describe "#resend" do
    before { allow(UnblockBrevoTransactionalContact).to receive(:new).and_return(instance_double(UnblockBrevoTransactionalContact, call: true)) }

    it "envoie un nouveau code par email et redirige vers le formulaire" do
      expect { post :resend }
        .to change(LoginCode, :count).by(1)
        .and have_enqueued_mail(Agents::LoginCodeMailer, :login_code)
      expect(response).to redirect_to(code_agents_two_factor_verification_path)
    end

    it "débloque le contact auprès de Brevo" do
      unblock = instance_double(UnblockBrevoTransactionalContact, call: true)
      allow(UnblockBrevoTransactionalContact).to receive(:new).with(agent.email).and_return(unblock)
      expect(unblock).to receive(:call)
      post :resend
    end
  end

  describe "#verify" do
    let!(:login_code) { create(:login_code, email: agent.email) }

    context "avec un code valide" do
      it "marque la double authentification comme vérifiée et redirige vers la page demandée" do
        session[:two_factor_step_up_return_to] = "/agents/edit"

        post :verify, params: { login_code: { code: login_code.code } }

        expect(session[:agent_2fa_verified_at]).to be_present
        expect(response).to redirect_to("/agents/edit")
        expect(session[:two_factor_step_up_return_to]).to be_nil
      end

      it "redirige vers la liste des exports avec un message quand la page demandée était un téléchargement d'export" do
        session[:two_factor_step_up_return_to] = "/agents/exports/42/download"

        post :verify, params: { login_code: { code: login_code.code } }

        expect(response).to redirect_to(agents_exports_path)
        expect(flash[:success]).to be_present
      end

      it "marque le code comme utilisé" do
        post :verify, params: { login_code: { code: login_code.code } }
        expect(login_code.reload.used_at).to be_present
      end

      it "redirige vers la page des exports quand aucune page de retour n'est mémorisée" do
        post :verify, params: { login_code: { code: login_code.code } }
        expect(response).to redirect_to(agents_exports_path)
      end
    end

    context "avec un code invalide" do
      it "ne marque pas la double authentification comme vérifiée" do
        post :verify, params: { login_code: { code: "000000" } }
        expect(session[:agent_2fa_verified_at]).to be_nil
      end

      it "réaffiche le formulaire de saisie du code" do
        post :verify, params: { login_code: { code: "000000" } }
        expect(response).to render_template(:code)
      end
    end
  end
end
