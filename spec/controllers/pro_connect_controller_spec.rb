RSpec.describe ProConnectController do
  stub_env_for_proconnect

  describe "#auth" do
    it "redirects to ProConnect" do
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
              essential: false,
              values: %w[eidas2 eidas3 https://proconnect.gouv.fr/assurance/consistency-checked-2fa https://proconnect.gouv.fr/assurance/self-asserted-2fa],
            },
          },
        }.to_json
      )
    end

    describe "with the for_user param" do
      it "saves the information that we want to log in a user rather than an agent in the session" do
        get :auth, params: { login_hint: "francis.factice@exemple.gouv.fr", user_type: "user" }

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
                essential: false,
                values: %w[eidas2 eidas3 https://proconnect.gouv.fr/assurance/consistency-checked-2fa https://proconnect.gouv.fr/assurance/self-asserted-2fa],
              },
            },
          }.to_json
        )
        expect(session["pro_connect"][:connection_for]).to eq("user")
      end
    end
  end

  describe "with the for_super_admin param" do
    it "adds the force_2fa param to the request" do
      get :auth, params: { user_type: "super_admin" }
      expect(response).to redirect_to(start_with("https://fca.integ01.dev-agentconnect.fr/api/v2/authorize?"))

      redirect_url = response.headers["Location"]
      redirect_url_query_params = Rack::Utils.parse_query(URI.parse(redirect_url).query)

      expect(redirect_url_query_params.symbolize_keys).to match(
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
              values: %w[eidas2 eidas3 https://proconnect.gouv.fr/assurance/consistency-checked-2fa https://proconnect.gouv.fr/assurance/self-asserted-2fa],
            },
          },
        }.to_json
      )
      expect(session["pro_connect"][:connection_for]).to eq("super_admin")
    end
  end

  describe "#callback" do
    let(:state) { auth_client.state }
    let(:auth_client) do
      ProConnectOpenIdClient::Auth.new(
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
        "siret" => "13002526500013",
        "aud" => "4ec41582-1d60-4f12-a63b-d8abaace16ba",
        "exp" => 1717595030, "iat" => 1717594970, "iss" => "https://fca.integ01.dev-agentconnect.fr/api/v2",
      }
    end

    before do
      session[:pro_connect] = {
        state: state,
        connection_for: "agent",
      }
      ProConnectStubs.stub_callback_requests(code, user_info)

      session[:agent_return_to] = "/agents/edit" # Pour simuler le retour vers la page demandée avant la connexion
    end

    describe "agent login" do
      def expect_agent_to_be_updated_and_logged_in(agent)
        expected_attrs = {
          pro_connect_openid_sub: user_info["sub"],
          email: user_info["email"],
          first_name: "Francis",
          last_name: "Factice",
        }
        expect(agent).to have_attributes(expected_attrs)
        expect(current_agent_id).to eq(agent.id)
        expect(session["pro_connect_id_token"]).to be_present
        expect(response).to redirect_to("/agents/edit")
      end

      context "when no existing agent matches email nor sub" do
        it "displays an error if the domain does not allow self-onboarding" do
          allow(Domain::RDV_SERVICE_PUBLIC).to receive(:allow_self_onboarding).and_return(false)
          expect do
            get :callback, params: { state:, code: }
          end.not_to change(Agent, :count)
          expect(flash[:error]).to include("Il n'y a pas de compte agent pour l'adresse mail #{user_info['email']}")
          expect(current_agent_id).to be_nil
        end

        it "creates the agent if the domain allows it" do
          allow(Domain::RDV_SERVICE_PUBLIC).to receive(:allow_self_onboarding).and_return(true)
          expect do
            get :callback, params: { state:, code: }
          end.to change(Agent, :count).by(1)
          agent = Agent.last
          expect_agent_to_be_updated_and_logged_in(agent)
        end
      end

      context "when an agent exists with the given email address and no sub" do
        it "updates the existing agent's sub" do
          agent = create(:agent, email: user_info["email"])
          expect do
            get :callback, params: { state:, code: }
          end.to change { agent.reload.pro_connect_openid_sub }.to(user_info["sub"])
          expect_agent_to_be_updated_and_logged_in(agent)
        end
      end

      context "when an agent exists with the given sub and another email address" do
        it "replaces the agents email address with the one from ProConnect" do
          agent = create(:agent, pro_connect_openid_sub: user_info["sub"], email: "autre@exemple.fr")
          expect do
            get :callback, params: { state:, code: }
          end.to change { agent.reload.email }.from("autre@exemple.fr").to(user_info["email"])
          expect_agent_to_be_updated_and_logged_in(agent)
          expect(flash[:info]).to include("Note : votre adresse e-mail a été mise à jour depuis ProConnect. Ancienne adresse : autre@exemple.fr, nouvelle adresse : #{user_info['email']}")
        end
      end

      context "when an agent exists with the given email but with another sub" do
        it "replaces the existing sub and warns Sentry" do
          agent = create(:agent, pro_connect_openid_sub: "another_sub", email: user_info["email"])
          expect do
            get :callback, params: { state:, code: }
          end.to change { Agent.find(agent.id).pro_connect_openid_sub }.from("another_sub").to(user_info["sub"])

          expect_agent_to_be_updated_and_logged_in(agent.reload)

          sentry_warning_message = "Réconciliation ProConnect via e-mail, sub existant écrasé"
          expect(sentry_events.last.message).to include(sentry_warning_message)
          expect(sentry_events.last.extra).to eq({ user_info: })
          expect(sentry_events.last.user[:email]).to eq(user_info["email"])
        end
      end

      context "when an agent exists with the given sub, and another agent exists with the given email" do
        it "displays an error and warns Sentry" do
          agent_by_sub = create(:agent, pro_connect_openid_sub: user_info["sub"])
          agent_by_email = create(:agent, email: user_info["email"])
          expect do
            get :callback, params: { state:, code: }
          end.not_to change { Agent.maximum(:updated_at) }
          expected_error_message = "Il existe deux comptes correspondant : #{agent_by_email.email} et #{agent_by_sub.email}"
          expect(flash[:error]).to include(expected_error_message)
          expect(sentry_events.last.message).to include(expected_error_message)
          expect(sentry_events.last.extra).to eq({ user_info: })
          expect(sentry_events.last.user[:email]).to eq(user_info["email"])
          expect(current_agent_id).to be_nil
        end
      end

      context "when an agent exists with the given email but with another sub, and another agent exists with the given sub but another email" do
        it "displays an error and warns Sentry" do
          create(:agent, pro_connect_openid_sub: "another_sub", email: user_info["email"])
          create(:agent, pro_connect_openid_sub: user_info["sub"], email: "autre@exemple.fr")
          expect do
            get :callback, params: { state:, code: }
          end.not_to change { Agent.maximum(:updated_at) }
          expected_error_message = "Il existe deux comptes correspondant : #{user_info['email']} et autre@exemple.fr"
          expect(flash[:error]).to include(expected_error_message)
          expect(sentry_events.last.message).to include(expected_error_message)
          expect(sentry_events.last.extra).to eq({ user_info: })
          expect(sentry_events.last.user[:email]).to eq(user_info["email"])
          expect(current_agent_id).to be_nil
        end
      end
    end

    context "when logging in a user" do
      before do
        session[:pro_connect] = {
          state:,
          connection_for: "user",
        }
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
        expect(session["pro_connect_id_token"]).to be_present

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
          expect(session["pro_connect_id_token"]).to be_present

          expect(response).to redirect_to("/users/informations")
        end
      end
    end

    context "when logging in a super admin" do
      before do
        session[:pro_connect] = {
          state:,
          connection_for: "super_admin",
        }
        session[:super_admin_return_to] = "/super_admins/lieux?search=arques" # Pour simuler le retour vers la page demandée avant la connexion
      end

      context "with a non 2FA account" do
        it "redirects to the super admin sign in page if the super admin does not activate 2FA" do
          get :callback, params: { state: state, code: code }

          expect(session["pro_connect_id_token"]).to be_nil
          expect(response).to redirect_to("/connexion_super_admins")
          expect(flash[:error]).to eq("Vous devez activer la double authentification sur votre compte ProConnect pour vous connecter en tant que super administrateur.")
        end
      end

      context "with a 2FA account" do
        before do
          ProConnectStubs.stub_callback_requests(code, user_info, with_2fa: true)
        end

        context "when the super admin does not exist" do
          it "redirects to the super admin sign in page" do
            get :callback, params: { state: state, code: code }

            expect(session["pro_connect_id_token"]).to be_nil
            expect(response).to redirect_to("/connexion_super_admins")
            expect(flash[:error]).to eq("Compte ProConnect non autorisé")
          end
        end

        context "when the super admin already exists" do
          let!(:super_admin) { create(:super_admin, email: user_info["email"]) }

          it "redirects to the super admin agents page" do
            get :callback, params: { state: state, code: code }

            expect(session["pro_connect_id_token"]).to be_present
            expect(response).to redirect_to("/super_admins/lieux?search=arques")
          end
        end

        context "in development, when no super admin exists" do
          before do
            allow(Rails).to receive(:env).and_return(ActiveSupport::StringInquirer.new("development"))
          end

          it "creates the super admin and redirects to the super admin agents page" do
            expect(SuperAdmin.count).to eq(0)

            get :callback, params: { state: state, code: code }

            expect(SuperAdmin.count).to eq(1)
            expect(SuperAdmin.last).to have_attributes(
              email: user_info["email"]
            )
            expect(session["pro_connect_id_token"]).to be_present
            expect(response).to redirect_to("/super_admins/lieux?search=arques")
          end
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
