RSpec.describe Agents::SessionsByCodeController, type: :controller do
  let(:agent) { create(:agent, sensitive_account: true) }

  describe "#new" do
    context "quand il n'y a pas de connexion en attente dans la session" do
      it "redirige vers la page de connexion" do
        get :new
        expect(response).to redirect_to(new_agent_session_path)
      end
    end

    context "quand il y a une connexion en attente dans la session" do
      before { session[Agents::SessionsByCodeController::SESSION_AGENT_ID_KEY] = agent.id }

      it "affiche le formulaire de saisie du code" do
        get :new
        expect(response).to have_http_status(:ok)
      end

      it "ne crée pas de code" do
        expect { get :new }.not_to change(LoginCode, :count)
      end
    end
  end

  describe "#resend" do
    context "quand il n'y a pas de connexion en attente dans la session" do
      it "redirige vers la page de connexion" do
        post :resend
        expect(response).to redirect_to(new_agent_session_path)
      end
    end

    context "quand il y a une connexion en attente dans la session" do
      before { session[Agents::SessionsByCodeController::SESSION_AGENT_ID_KEY] = agent.id }

      it "crée et envoie un nouveau code par email" do
        expect { post :resend }
          .to change(LoginCode, :count).by(1)
          .and have_enqueued_mail(Agents::LoginCodeMailer, :login_code)
        expect(LoginCode.last.email).to eq(agent.email)
      end

      it "redirige vers le formulaire de saisie du code" do
        post :resend
        expect(response).to redirect_to(new_agents_sessions_by_code_path)
      end
    end
  end

  describe "#create" do
    let!(:login_code) { create(:login_code, email: agent.email) }

    context "quand il n'y a pas de connexion en attente dans la session" do
      it "redirige vers la page de connexion" do
        post :create, params: { login_code: { code: login_code.code } }
        expect(response).to redirect_to(new_agent_session_path)
      end
    end

    context "quand il y a une connexion en attente dans la session" do
      before { session[Agents::SessionsByCodeController::SESSION_AGENT_ID_KEY] = agent.id }

      context "avec un code valide" do
        it "connecte l'agent" do
          post :create, params: { login_code: { code: login_code.code } }
          expect(current_agent_id).to eq(agent.id)
        end

        it "supprime la connexion en attente de la session" do
          post :create, params: { login_code: { code: login_code.code } }
          expect(session[Agents::SessionsByCodeController::SESSION_AGENT_ID_KEY]).to be_nil
        end

        it "redirige après la connexion" do
          post :create, params: { login_code: { code: login_code.code } }
          expect(response).to be_redirect
        end

        it "marque le code comme utilisé" do
          post :create, params: { login_code: { code: login_code.code } }
          expect(login_code.reload.used_at).to be_present
        end

        context "quand un token ProConnect en attente est présent dans la session" do
          before { session[Agents::SessionsByCodeController::SESSION_PRO_CONNECT_ID_TOKEN_KEY] = "fake_pro_connect_token" }

          it "transfère le token vers pro_connect_id_token et supprime le pending" do
            post :create, params: { login_code: { code: login_code.code } }
            expect(session[:pro_connect_id_token]).to eq("fake_pro_connect_token")
            expect(session[Agents::SessionsByCodeController::SESSION_PRO_CONNECT_ID_TOKEN_KEY]).to be_nil
          end
        end
      end

      context "avec un code invalide" do
        it "ne connecte pas l'agent" do
          post :create, params: { login_code: { code: "000000" } }
          expect(current_agent_id).to be_nil
        end

        it "réaffiche le formulaire" do
          post :create, params: { login_code: { code: "000000" } }
          expect(response).to render_template(:new)
        end
      end

      context "avec un code déjà utilisé" do
        before { login_code.update!(used_at: Time.zone.now) }

        it "ne connecte pas l'agent" do
          post :create, params: { login_code: { code: login_code.code } }
          expect(current_agent_id).to be_nil
        end
      end
    end
  end
end
