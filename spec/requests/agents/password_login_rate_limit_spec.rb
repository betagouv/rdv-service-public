RSpec.describe "rate limiting de la connexion agent par mot de passe", type: :request do
  include_context "enable rack-attack"

  let!(:agent) { create(:agent, email: "agent@example.fr", password: "c0rrecThorse!") }

  it "throttle après quelques tentatives avec un mauvais mot de passe" do
    2.times do
      post agent_session_path, params: { agent: { email: "agent@example.fr", password: "mauvais" } }
      expect(response).not_to redirect_to("/500.html")
    end

    post agent_session_path, params: { agent: { email: "agent@example.fr", password: "c0rrecThorse!" } }
    expect(response).to redirect_to("/500.html")
    expect(sentry_events.last.level).to eq(:warning)
    expect(sentry_events.last.exception.values.last.type).to eq("Rack::Attack::ThrottleError")
  end

  it "throttle par email même depuis des IP différentes et en changeant la casse" do
    post agent_session_path, params: { agent: { email: "agent@example.fr", password: "mauvais" } }, env: { "REMOTE_ADDR" => "1.1.1.1" }
    post agent_session_path, params: { agent: { email: " AGENT@example.fr", password: "mauvais" } }, env: { "REMOTE_ADDR" => "2.2.2.2" }

    post agent_session_path, params: { agent: { email: "Agent@Example.fr ", password: "mauvais" } }, env: { "REMOTE_ADDR" => "3.3.3.3" }
    expect(response).to redirect_to("/500.html")
    expect(sentry_events.last.exception.values.last.value).to include("throttling par email")
  end
end
