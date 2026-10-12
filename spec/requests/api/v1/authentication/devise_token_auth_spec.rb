RSpec.describe "API authentication" do
  # inspired by https://devise-token-auth.gitbook.io/devise-token-auth/usage/testing

  let!(:organisation) { create(:organisation) }
  let!(:agent) { create(:agent, email: "agent.api@example.fr", password: "Correcth0rse!", admin_role_in_organisations: [organisation]) }
  let!(:absence) { create(:absence, agent: agent) }

  stub_env_with(AUTHORIZE_DEPRECATED_API_AUTH_FOR_EMAILS: "autre.agent@example.fr; Agent.API@example.fr ")

  context "login with wrong password" do
    it "returns error" do
      post(
        api_v1_agent_with_token_auth_session_path,
        params: { email: agent.email, password: "blahblah" }.to_json,
        headers: { CONTENT_TYPE: "application/json", ACCEPT: "application/json" }
      )
      expect(response.status).to eq(401)
      expect(response.has_header?("access-token")).to be(false)
    end
  end

  context "login with wrong email" do
    it "returns error" do
      post(
        api_v1_agent_with_token_auth_session_path,
        params: { email: "blah@demo.rdv-sol.fr", password: "Correcth0rse!" }.to_json,
        headers: { CONTENT_TYPE: "application/json", ACCEPT: "application/json" }
      )
      expect(response.status).to eq(401)
      expect(response.has_header?("access-token")).to be(false)
    end
  end

  context "query endpoint without auth headers" do
    it "returns error" do
      get api_v1_absences_path
      expect(response.status).to eq(401)
    end
  end

  context "query any endpoint with mistaken auth headers" do
    it "returns error" do
      get(
        api_v1_absences_path,
        headers: {
          "access-token": "blah",
          client: "blah",
          uid: "jean@fun.fr",
        }
      )
      expect(response.status).to eq(401)
    end
  end

  context "log in, then query" do
    it "gives you an authentication code if you are an existing user and you satisfy the password" do
      post(
        api_v1_agent_with_token_auth_session_path,
        params: { email: agent.email, password: "Correcth0rse!" }.to_json,
        headers: { CONTENT_TYPE: "application/json", ACCEPT: "application/json" }
      )
      expect(response.status).to eq(200)
      expect(response.has_header?("access-token")).to be(true)
      get(
        api_v1_absences_path,
        headers: {
          "access-token": response.headers["access-token"],
          client: response.headers["client"],
          uid: response.headers["uid"],
        }
      )
      expect(response.status).to eq(200)
      expect(parsed_response_body["absences"].count).to eq(1)
    end
  end

  describe "GET api/v1/auth/validate_token" do
    subject { get api_v1_auth_validate_token_path, headers: api_auth_headers_for_agent(agent) }

    it "returns the agent credentials" do
      subject
      expect(response.status).to eq(200)
      expect(parsed_response_body["data"]["email"]).to eq("agent.api@example.fr")
    end
  end

  it "ne monte que les routes de connexion et de validation de token" do
    paths = Rails.application.routes.routes.map { it.path.spec.to_s }.grep(%r{\A/api/v1/auth/}).uniq

    expect(paths).to contain_exactly("/api/v1/auth/sign_in(.:format)", "/api/v1/auth/sign_out(.:format)", "/api/v1/auth/validate_token(.:format)")
  end

  context "quand l'agent n'est pas dans la liste des emails autorisés" do
    let!(:agent_hors_liste) { create(:agent, password: "Correcth0rse!", admin_role_in_organisations: [organisation]) }

    it "refuse la connexion, comme pour un email inexistant" do
      post(
        api_v1_agent_with_token_auth_session_path,
        params: { email: agent_hors_liste.email, password: "Correcth0rse!" }.to_json,
        headers: { CONTENT_TYPE: "application/json", ACCEPT: "application/json" }
      )
      expect(response.status).to eq(401)
      expect(response.has_header?("access-token")).to be(false)
      expect(parsed_response_body["errors"]).to eq(["Mot de passe ou identifiant invalide."])
    end

    it "refuse un token émis avant la restriction" do
      token_headers = AgentWithTokenAuth.find(agent_hors_liste.id).create_new_auth_token

      get api_v1_absences_path, headers: token_headers
      expect(response.status).to eq(401)

      get api_v1_auth_validate_token_path, headers: token_headers
      expect(response.status).to eq(401)
    end
  end

  context "quand la liste des emails autorisés est vide (comme sur RDV Service Public)" do
    stub_env_with(AUTHORIZE_DEPRECATED_API_AUTH_FOR_EMAILS: nil)

    it "refuse la connexion par email et mot de passe" do
      post(
        api_v1_agent_with_token_auth_session_path,
        params: { email: agent.email, password: "Correcth0rse!" }.to_json,
        headers: { CONTENT_TYPE: "application/json", ACCEPT: "application/json" }
      )
      expect(response.status).to eq(401)
      expect(response.has_header?("access-token")).to be(false)
    end

    it "refuse la validation d'un token" do
      token_headers = AgentWithTokenAuth.find(agent.id).create_new_auth_token

      get api_v1_auth_validate_token_path, headers: token_headers
      expect(response.status).to eq(401)
    end

    it "refuse un token devise_token_auth" do
      token_headers = AgentWithTokenAuth.find(agent.id).create_new_auth_token

      get api_v1_absences_path, headers: token_headers
      expect(response.status).to eq(401)
    end
  end
end
