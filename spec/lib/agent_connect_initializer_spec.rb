RSpec.describe "AGENT_CONNECT_CONFIG" do
  context "when Agent Connect is not accessible" do
    before do
      stub_request(:get, "https://fca.integ01.dev-agentconnect.fr/api/v2/.well-known/openid-configuration")
        .to_return(status: 500, body: "", headers: {})
    end

    it "doesn't raise an error that would keep the application from booting up, but it sends an exception in Sentry" do
      expect(Sentry).to receive(:capture_exception)
      expect { load "#{::Rails.root}/config/initializers/agent_connect.rb" }.not_to(raise_error)
      expect(AGENT_CONNECT_UNREACHABLE_AT_BOOT_TIME).to be true
    end
  end

  context "when Agent Connect is accessible" do
    before do
      stub_request(:get, "https://fca.integ01.dev-agentconnect.fr/api/v2/.well-known/openid-configuration")
        .to_return(status: 200, body: File.read("#{::Rails.root}/spec/fixtures/agent_connect/openid-configuration.json"), headers: {})
    end

    it "starts the application normally" do
      load "#{::Rails.root}/config/initializers/agent_connect.rb"
      expect(AGENT_CONNECT_UNREACHABLE_AT_BOOT_TIME).to be false
    end
  end
end
