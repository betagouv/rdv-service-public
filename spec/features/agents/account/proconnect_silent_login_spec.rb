RSpec.describe "Agent is automatically logged in with pro connect" do
  let(:code) { "IDej8hpYou2rZLsDgTzZ_nMl1aXmNajpByd20dig4e8" }
  let(:user_info) do
    {
      "sub" => "ab70770d-1285-46e6-b4d0-3601b49698d4",
      "email" => "francis.factice@exemple.gouv.fr",
      "given_name" => "Francis Factice",
      "usual_name" => "Factice",
      "siret" => "13002526500013",
      "idp_id" => "fia1",
      "aud" => "4ec41582-1d60-4f12-a63b-d8abaace16ba",
      "exp" => 1717595030, "iat" => 1717594970, "iss" => "https://fca.integ01.dev-agentconnect.fr/api/v2",
    }
  end

  stub_env_for_proconnect

  around do |example|
    previous_host = Capybara.app_host
    Capybara.app_host = "http://www.rdv-service-public-test.localhost:#{previous_host[/\d+/]}"
    example.run
    Capybara.app_host = previous_host
  end

  before { ProConnectStubs.stub_callback_requests(code, user_info, host: Capybara.app_host) }

  context "an existing agent tries to connect to a page requiring authentication" do
    let!(:organisation) { create(:organisation) }
    let!(:agent) { create(:agent, admin_role_in_organisations: [organisation], email: "francis.factice@exemple.gouv.fr") }

    it "logs in the agent automatically if they are signed in to ProConnect" do
      begin
        visit admin_organisation_rdvs_path(organisation)
      rescue ActionController::RoutingError
        # Capybara essaye de suivre une redirection vers "https://fca.integ01.dev-agentconnect.fr/api/v2/authorize
        # ce qui n'est pas possible dans l'env de test (il ignore le host et il cherche /api/v2/authorize dans nos routes).
      end

      expect(page.current_url).to start_with("https://fca.integ01.dev-agentconnect.fr/api/v2/authorize")
      redirect_url_query_params = Rack::Utils.parse_query(URI.parse(page.current_url).query)

      expect(redirect_url_query_params.symbolize_keys).to match(
        client_id: "ec41582-1d60-4f11-a63b-d8abaece16aa", # Le client id utilisé par stub_env_for_proconnect
        redirect_uri: "#{Capybara.app_host}/agent_connect/callback",
        response_type: "code",
        prompt: "none",
        scope: "openid email given_name usual_name siret idp_id",
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

      state = redirect_url_query_params["state"]

      # On simule le redirect de ProConnect
      visit pro_connect_callback_path(code:, state:)

      expect(page).to have_content "Liste des RDV"
      expect(page).to have_content "Vous avez été connecté automatiquement par ProConnect"
    end

    context "when ProConnect is disabled, possibly because it is down" do
      stub_env_with(PRO_CONNECT_DISABLED: "true")

      it "redirects to the sign_in page" do
        visit admin_organisation_rdvs_path(organisation)
        expect(page).to have_content "Entrez votre email et votre mot de passe"
        expect(page.current_url).to end_with("/agents/sign_in")
      end
    end

    context "when the current domain doesn't have a proconnect setup" do
      stub_env_with(
        PRO_CONNECT_RDVSP_CLIENT_SECRET: nil,
        PRO_CONNECT_RDVSP_CLIENT_ID: nil
      )

      it "redirects to the sign_in page" do
        visit admin_organisation_rdvs_path(organisation)
        expect(page).to have_content "Entrez votre email et votre mot de passe"
        expect(page.current_url).to end_with("/agents/sign_in")
      end
    end

    it "redirects to the login page when the agent is not logged in to ProConnect" do
      begin
        visit admin_organisation_rdvs_path(organisation)
      rescue ActionController::RoutingError
        # A cause de Capybara qui ignore le domain name
      end

      redirect_url_query_params = Rack::Utils.parse_query(URI.parse(page.current_url).query)
      state = redirect_url_query_params["state"]

      # On simule le redirect de ProConnect
      visit pro_connect_callback_path(error: "login_required", error_description: "End-User authentication is required", state:)

      expect(page).to have_content "Vous devez vous connecter pour continuer"

      expect(page).to have_content "Entrez votre email et votre mot de passe"
      expect(page.current_url).to end_with("/agents/sign_in")
    end
  end

  context "when there is no agent account for this email, probably because the agent logs in with email/password through another email address" do
    let(:organisation) { create(:organisation) }

    context "when it's their first proconnect login for the other account" do
      it "doesn't log them in and redirects to the login screen instead, to avoid blocking agents using email/password login" do
        begin
          visit admin_organisation_rdvs_path(organisation)
        rescue ActionController::RoutingError
          # A cause de Capybara qui ignore le domain name
        end

        redirect_url_query_params = Rack::Utils.parse_query(URI.parse(page.current_url).query)

        state = redirect_url_query_params["state"]

        visit pro_connect_callback_path(code:, state:)

        expect(page).to have_content "Connexion agent à RDV Service Public"
      end
    end
  end

  context "when logging in through an OAuth client app" do
    let(:oauth_application) do
      create(:oauth_application, name: "Démarches Simplifiées")
    end

    it "also allows silently logging in even if the agent doesn't already exist" do
      begin
        visit oauth_authorization_path(
          client_id: oauth_application.uid,
          redirect_uri: oauth_application.redirect_uri.split("\n").first,
          response_type: :code, scope: :write, state: "fakestate"
        )
      rescue ActionController::RoutingError
        # Capybara essaye de suivre une redirection vers "https://fca.integ01.dev-agentconnect.fr/api/v2/authorize
        # ce qui n'est pas possible dans l'env de test (il ignore le host et il cherche /api/v2/authorize dans nos routes).
      end

      expect(page.current_url).to start_with("https://fca.integ01.dev-agentconnect.fr/api/v2/authorize")
      redirect_url_query_params = Rack::Utils.parse_query(URI.parse(page.current_url).query)

      expect(redirect_url_query_params.symbolize_keys).to match(
        client_id: "ec41582-1d60-4f11-a63b-d8abaece16aa",
        redirect_uri: "#{Capybara.app_host}/agent_connect/callback",
        response_type: "code",
        prompt: "none",
        scope: "openid email given_name usual_name siret idp_id",
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

      state = redirect_url_query_params["state"]

      # On simule le redirect de ProConnect
      visit pro_connect_callback_path(code:, state:)

      expect(page).to have_content "Validation de permissions"
      expect(page).to have_content "Vous avez été connecté automatiquement par ProConnect"
    end
  end
end
