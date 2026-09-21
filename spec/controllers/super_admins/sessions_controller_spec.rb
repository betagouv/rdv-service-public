RSpec.describe SuperAdmins::SessionsController do
  describe "#destroy" do
    context "quand le super admin est connecté" do
      let(:super_admin) { create(:super_admin) }

      before { sign_in super_admin, scope: :super_admin }

      it "déconnecte le super admin et redirige vers la page d'accueil" do
        delete :destroy

        expect(session["warden.user.super_admin.key"]).to be_nil
        expect(response).to redirect_to(root_path)
      end

      it "vide la session dans son intégralité" do
        session[:some_unrelated_key] = "devrait disparaître"
        delete :destroy
        expect(session[:some_unrelated_key]).to be_nil
      end

      context "et était connecté via ProConnect" do
        stub_env_with(PRO_CONNECT_BASE_URL: "https://fca.integ01.dev-agentconnect.fr/api/v2")

        before do
          ProConnectStubs.stub_and_run_discover_request
          session[:pro_connect_id_token] = "fake_pro_connect_id_token"
        end

        it "redirige vers l'url de déconnexion ProConnect avec les bons paramètres" do
          delete :destroy
          expect(session[:pro_connect_id_token]).to be_nil

          redirect_url = response.headers["Location"]
          expect(redirect_url).to start_with("https://fca.integ01.dev-agentconnect.fr/api/v2/session/end")

          redirect_url_query_params = Rack::Utils.parse_query(URI.parse(redirect_url).query)
          expect(redirect_url_query_params.symbolize_keys).to match(
            id_token_hint: "fake_pro_connect_id_token",
            state: anything,
            post_logout_redirect_uri: "http://test.host/"
          )
        end
      end
    end

    context "quand le super admin n'est pas (ou plus) connecté" do
      it "ne fait rien et redirige vers la page de connexion (bloqué par authenticate_super_admin! avant d'atteindre l'action)" do
        session[:some_unrelated_key] = "devrait survivre"
        delete :destroy

        expect(session[:some_unrelated_key]).to eq("devrait survivre")
        expect(response).to redirect_to(connexion_super_admins_path)
      end
    end
  end
end
