RSpec.describe "rate limiting de la connexion agent par l'API dépréciée devise_token_auth", type: :request do
  include_context "enable rack-attack"
  stub_env_with(AUTHORIZE_DEPRECATED_API_AUTH_FOR_EMAILS: "agent@example.fr")

  let!(:agent) { create(:agent, email: "agent@example.fr", password: "c0rrecThorse!") }

  it "throttle par email même depuis des IP différentes et en changeant la casse" do
    post api_v1_agent_with_token_auth_session_path, params: { email: "agent@example.fr", password: "mauvais" }.to_json,
                                                    headers: { CONTENT_TYPE: "application/json" }, env: { "REMOTE_ADDR" => "1.1.1.1" }
    post api_v1_agent_with_token_auth_session_path, params: { email: " AGENT@example.fr", password: "mauvais" }.to_json,
                                                    headers: { CONTENT_TYPE: "application/json" }, env: { "REMOTE_ADDR" => "2.2.2.2" }
    expect(response).not_to redirect_to("/500.html")

    post api_v1_agent_with_token_auth_session_path, params: { email: "Agent@example.fr", password: "c0rrecThorse!" }.to_json,
                                                    headers: { CONTENT_TYPE: "application/json" }, env: { "REMOTE_ADDR" => "3.3.3.3" }
    expect(response).to redirect_to("/500.html")
    expect(response.has_header?("access-token")).to be(false)
    expect(sentry_events.last.exception.values.last.value).to include("API dépréciée - throttling par email")
  end

  it "throttle par IP" do
    post api_v1_agent_with_token_auth_session_path, params: { email: "a@example.fr", password: "mauvais" }.to_json,
                                                    headers: { CONTENT_TYPE: "application/json" }
    post api_v1_agent_with_token_auth_session_path, params: { email: "b@example.fr", password: "mauvais" }.to_json,
                                                    headers: { CONTENT_TYPE: "application/json" }
    expect(response).not_to redirect_to("/500.html")

    post api_v1_agent_with_token_auth_session_path, params: { email: "c@example.fr", password: "mauvais" }.to_json,
                                                    headers: { CONTENT_TYPE: "application/json" }
    expect(response).to redirect_to("/500.html")
    expect(sentry_events.last.exception.values.last.value).to include("API dépréciée - throttling par IP")
  end
end
