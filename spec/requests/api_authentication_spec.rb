# frozen_string_literal: true

describe "API auth", type: :request do
  # inspired by https://devise-token-auth.gitbook.io/devise-token-auth/usage/testing

  let!(:organisation) { create(:organisation) }
  let!(:agent) { create(:agent, password: "123456", basic_role_in_organisations: [organisation]) }
  let!(:absence) { create(:absence, agent: agent, organisation: organisation) }

  context "login with wrong password" do
    it "returns error" do
      post(
        api_v1_agent_with_token_auth_session_path,
        params: { email: agent.email, password: "blahblah" }.to_json,
        headers: { CONTENT_TYPE: "application/json", ACCEPT: "application/json" }
      )
      expect(response.status).to eq(401)
      expect(response.has_header?("access-token")).to eq(false)
    end
  end

  context "login with wrong email" do
    it "returns error" do
      post(
        api_v1_agent_with_token_auth_session_path,
        params: { email: "blah@demo.rdv-sol.fr", password: "123456" }.to_json,
        headers: { CONTENT_TYPE: "application/json", ACCEPT: "application/json" }
      )
      expect(response.status).to eq(401)
      expect(response.has_header?("access-token")).to eq(false)
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
        params: { email: agent.email, password: "123456" }.to_json,
        headers: { CONTENT_TYPE: "application/json", ACCEPT: "application/json" }
      )
      expect(response.status).to eq(200)
      expect(response.has_header?("access-token")).to eq(true)
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

    let!(:agent) { create(:agent, email: "amine.dhobb@beta.gouv.fr") }

    it "returns the agent credentials" do
      subject
      expect(response.status).to eq(200)
      expect(parsed_response_body["data"]["email"]).to eq("amine.dhobb@beta.gouv.fr")
    end
  end
end
