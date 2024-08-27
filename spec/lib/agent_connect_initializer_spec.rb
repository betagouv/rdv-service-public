RSpec.describe "Agent Connect initializer" do # rubocop:disable RSpec/DescribeClass
  stub_env_with(AGENT_CONNECT_BASE_URL: "https://fca.integ01.dev-agentconnect.fr/api/v2")

  context "when Agent Connect is not accessible" do
    before do
      stub_request(:get, "https://fca.integ01.dev-agentconnect.fr/api/v2/.well-known/openid-configuration")
        .to_return(status: 500, body: "", headers: {})
    end

    it "doesn't raise an error that would keep the application from booting up, but it sends an exception in Sentry" do
      expect { load "#{Rails.root.join("config/initializers/agent_connect.rb")}" }.not_to(raise_error)
      expect(Rails.configuration.x.agent_connect_unreachable_at_boot_time).to be true

      expect(sentry_events.last.message).to include("Agent Connect n'est pas joignable au démarrage de l'application")
    end
  end

  context "when Agent Connect is accessible" do
    before do
      stub_request(:get, "https://fca.integ01.dev-agentconnect.fr/api/v2/.well-known/openid-configuration")
        .to_return(status: 200, body: File.read("#{Rails.root.join("spec/fixtures/agent_connect/openid-configuration.json")}"), headers: {})
    end

    it "starts the application normally" do
      load "#{Rails.root.join("config/initializers/agent_connect.rb")}"
      expect(Rails.configuration.x.agent_connect_unreachable_at_boot_time).to be false
    end
  end
end
