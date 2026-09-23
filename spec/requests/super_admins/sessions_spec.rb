RSpec.describe "SuperAdmins::Sessions", type: :request do
  describe "DELETE /super_admins/sign_out" do
    context "quand le super admin est connecté" do
      let(:super_admin) { create(:super_admin) }

      before { login_as(super_admin, scope: :super_admin) }

      it "déconnecte le super admin et redirige vers la page d'accueil" do
        delete super_admins_sign_out_path

        expect(session["warden.user.super_admin.key"]).to be_nil
        expect(response).to redirect_to(root_path)
      end

      it "vide la session dans son intégralité" do
        agent = create(:agent)
        login_as(agent, scope: :agent)

        delete super_admins_sign_out_path

        expect(session["warden.user.super_admin.key"]).to be_nil
        expect(session["warden.user.agent.key"]).to be_nil
      end
    end

    context "quand le super admin est connecté via ProConnect" do
      stub_env_for_proconnect

      let(:code) { "IDej8hpYou2rZLsDgTzZ_nMl1aXmNajpByd20dig4e8" }
      let(:user_info) do
        {
          "sub" => "ab70770d-1285-46e6-b4d0-3601b49698d4",
          "email" => "francis.factice@exemple.fr",
          "given_name" => "Francis Factice",
          "usual_name" => "Factice",
          "siret" => "13002526500013",
          "idp_id" => "fia1",
          "aud" => "4ec41582-1d60-4f12-a63b-d8abaace16ba",
          "exp" => 1717595030, "iat" => 1717594970, "iss" => "https://fca.integ01.dev-agentconnect.fr/api/v2",
        }
      end
      let!(:super_admin) { create(:super_admin, email: user_info["email"]) }

      before do
        ProConnectStubs.stub_callback_requests(code, user_info, with_2fa: true, host: "http://www.example.com")

        get pro_connect_auth_path(user_type: "super_admin")
        state = Rack::Utils.parse_query(URI.parse(response.headers["Location"]).query)["state"]
        get pro_connect_callback_path(state:, code:)
      end

      it "redirige vers l'url de déconnexion ProConnect avec les bons paramètres" do
        delete super_admins_sign_out_path
        expect(session["pro_connect_id_token"]).to be_nil

        redirect_url = response.headers["Location"]
        expect(redirect_url).to start_with("https://fca.integ01.dev-agentconnect.fr/api/v2/session/end")

        redirect_url_query_params = Rack::Utils.parse_query(URI.parse(redirect_url).query)
        expect(redirect_url_query_params.symbolize_keys).to match(
          id_token_hint: "fake proconnect id token",
          state: anything,
          post_logout_redirect_uri: root_url
        )
      end
    end

    context "quand le super admin n'est pas (ou plus) connecté" do
      it "ne fait rien et redirige vers la page de connexion (bloqué par authenticate_super_admin! avant d'atteindre l'action)" do
        agent = create(:agent)
        login_as(agent, scope: :agent)

        delete super_admins_sign_out_path

        expect(session["warden.user.agent.key"]).to be_present
        expect(response).to redirect_to(connexion_super_admins_path)
      end
    end
  end
end
