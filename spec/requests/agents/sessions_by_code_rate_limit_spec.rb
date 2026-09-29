RSpec.describe "rate limiting de la saisie de code de connexion agent (compte sensible)", type: :request do
  include_context "enable rack-attack"

  let!(:agent) { create(:agent, password: "c0rrecThorse!", sensitive_account: true) }

  before do
    # Fait passer l'agent par le premier facteur (mot de passe), ce qui pose
    # `session[:pending_agent_login_id]` côté serveur — c'est cette valeur que le throttle doit utiliser.
    post agent_session_path, params: { agent: { email: agent.email, password: "c0rrecThorse!" } }
  end

  it "throttle après quelques tentatives même quand le code est correct" do
    2.times do
      post agents_sessions_by_code_path, params: { login_code: { code: "000000" } }
      expect(response).not_to redirect_to("/500.html")
    end

    post agents_sessions_by_code_path, params: { login_code: { code: "000000" } }
    expect(response).to redirect_to("/500.html")
    expect(sentry_events.last.level).to eq(:warning)
    expect(sentry_events.last.exception.values.last.type).to eq("Rack::Attack::ThrottleError")
  end

  it "throttle après quelques tentatives en faisant varier le champ email soumis" do
    3.times do |i|
      post agents_sessions_by_code_path, params: { login_code: { email: "attacker-#{i}@exemple.fr", code: "000000" } }
    end

    expect(response).to redirect_to("/500.html")
  end
end
