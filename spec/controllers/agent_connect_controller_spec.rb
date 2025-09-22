RSpec.describe AgentConnectController do
  stub_env_for_proconnect

  describe "#auth" do
    it "redirects to AgentConnect" do
      get :auth, params: { login_hint: "francis.factice@exemple.gouv.fr" }
      expect(response).to redirect_to(start_with("https://fca.integ01.dev-agentconnect.fr/api/v2/authorize?"))

      redirect_url = response.headers["Location"]
      redirect_url_query_params = Rack::Utils.parse_query(URI.parse(redirect_url).query)

      expect(redirect_url_query_params.symbolize_keys).to match(
        login_hint: "francis.factice@exemple.gouv.fr",
        client_id: "ec41582-1d60-4f11-a63b-d8abaece16aa",
        redirect_uri: "http://test.host/agent_connect/callback",
        response_type: "code",
        scope: "openid email given_name usual_name siret",
        state: be_a(String),
        nonce: be_a(String),
        claims: {
          id_token: {
            acr: {
              essential: true,
              values: ["eidas1"],
            },
          },
        }.to_json
      )
    end

    describe "with the for_user param" do
      it "saves the information that we want to log in a user rather than an agent in the session" do
        get :auth, params: { login_hint: "francis.factice@exemple.gouv.fr", for_user: true }

        expect(response).to redirect_to(start_with("https://fca.integ01.dev-agentconnect.fr/api/v2/authorize?"))

        redirect_url = response.headers["Location"]
        redirect_url_query_params = Rack::Utils.parse_query(URI.parse(redirect_url).query)

        expect(redirect_url_query_params.symbolize_keys).to match(
          login_hint: "francis.factice@exemple.gouv.fr",
          client_id: "ec41582-1d60-4f11-a63b-d8abaece16aa",
          redirect_uri: "http://test.host/agent_connect/callback",
          response_type: "code",
          scope: "openid email given_name usual_name siret",
          state: be_a(String),
          nonce: be_a(String),
          claims: {
            id_token: {
              acr: {
                essential: true,
                values: ["eidas1"],
              },
            },
          }.to_json
        )
        expect(session["proconnect_for_user"]).to be_present
      end
    end
  end

  describe "#callback" do
    let(:state) { auth_client.state }
    let(:auth_client) do
      AgentConnectOpenIdClient::Auth.new(
        client_id: "ec41582-1d60-4f11-a63b-d8abaece16aa",
        client_secret: "un faux secret de test"
      )
    end
    let(:code) { "IDej8hpYou2rZLsDgTzZ_nMl1aXmNajpByd20dig4e8" }

    let(:user_info) do
      {
        "sub" => "ab70770d-1285-46e6-b4d0-3601b49698d4",
        "email" => "francis.factice@exemple.gouv.fr",
        "given_name" => "Francis Factice",
        "usual_name" => "Factice",
        "aud" => "4ec41582-1d60-4f12-a63b-d8abaace16ba",
        "exp" => 1717595030, "iat" => 1717594970, "iss" => "https://fca.integ01.dev-agentconnect.fr/api/v2",
      }
    end

    before do
      session[:agent_connect_state] = state
      AgentConnectStubs.stub_callback_requests(code, user_info)

      session[:agent_return_to] = "/agents/edit" # Pour simuler le retour vers la page demandée avant la connexion
    end

    it "updates and logs in the agent" do
      agent = create(:agent, email: "francis.factice@exemple.gouv.fr")
      get :callback, params: { state: state, code: code }

      expect(agent.reload).to have_attributes(
        connected_with_agent_connect: true,
        first_name: "Francis",
        last_name: "Factice",
        last_sign_in_at: be_within(10.seconds).of(Time.zone.now)
      )
      expect(session["agent_connect_id_token"]).to be_present

      expect(response).to redirect_to("/agents/edit")
    end

    context "when logging in a user" do
      before do
        session["proconnect_for_user"] = true
        session[:user_return_to] = "/users/informations" # Pour simuler le retour vers la page demandée avant la connexion
      end

      it "creates the user" do
        expect do
          get :callback, params: { state: state, code: code }
        end.to change(User, :count).by(1)

        expect(User.last).to have_attributes(
          pro_connect_openid_sub: "ab70770d-1285-46e6-b4d0-3601b49698d4",
          first_name: "Francis",
          last_name: "Factice",
          confirmed_at: be_within(10.seconds).of(Time.zone.now)
        )
        expect(session["agent_connect_id_token"]).to be_present

        expect(response).to redirect_to("/users/informations")
      end

      context "when the user already exists" do
        let!(:user) { create(:user, pro_connect_openid_sub: "ab70770d-1285-46e6-b4d0-3601b49698d4") }

        it "updates and logs in the user" do
          get :callback, params: { state: state, code: code }

          expect(user.reload).to have_attributes(
            first_name: "Francis",
            last_name: "Factice"
          )
          expect(session["agent_connect_id_token"]).to be_present

          expect(response).to redirect_to("/users/informations")
        end
      end
    end

    context "when the agent has a name with two words" do
      let(:user_info) do
        {
          "sub" => "ab70770d-1285-46e6-b4d0-3601b49698d4",
          "email" => "jean.michel.factice@exemple.gouv.fr",
          "given_name" => "Jean Michel Factice",
          "usual_name" => "Factice",
          "siret" => "11006801200050",
          "aud" => "4ec41582-1d60-4f12-a63b-d8abaace16ba",
          "exp" => 1717595030, "iat" => 1717594970, "iss" => "https://fca.integ01.dev-agentconnect.fr/api/v2",
        }
      end

      it "sets the proper first and last name and siret for the agent" do
        agent = create(:agent, email: "jean.michel.factice@exemple.gouv.fr")
        get :callback, params: { state: state, code: code }

        expect(agent.reload).to have_attributes(
          first_name: "Jean Michel",
          last_name: "Factice",
          proconnect_siret: "11006801200050"
        )
      end
    end

    context "when the agent has a capital letter in their ProConnect email address" do
      let(:user_info) do
        {
          "sub" => "ab70770d-1285-46e6-b4d0-3601b49698d4",
          "email" => "JEAN.MICHEL.FACTICE@exemple.gouv.fr",
          "given_name" => "Jean Michel Factice",
          "usual_name" => "Factice",
          "siret" => "11006801200050",
          "aud" => "4ec41582-1d60-4f12-a63b-d8abaace16ba",
          "exp" => 1717595030, "iat" => 1717594970, "iss" => "https://fca.integ01.dev-agentconnect.fr/api/v2",
        }
      end

      it "finds the right agent and updates them" do
        agent = create(:agent, email: "JEAN.MICHEL.FACTICE@exemple.gouv.fr") # même si on crée l'agent avec des majuscule dans l'email, il sera persisté en base avec des minuscules
        get :callback, params: { state: state, code: code }

        expect(agent.reload).to have_attributes(
          first_name: "Jean Michel",
          last_name: "Factice",
          proconnect_siret: "11006801200050"
        )
      end
    end
  end
end
