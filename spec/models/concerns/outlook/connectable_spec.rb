# frozen_string_literal: true

RSpec.describe Outlook::Connectable, type: :concern do
  describe "#refresh_outlook_token" do
    before do
      stub_request(:post, "https://login.microsoftonline.com/common/oauth2/v2.0/token")
        .with(
          body: { "client_id" => nil, "client_secret" => nil, "grant_type" => "refresh_token", "refresh_token" => nil }
        )
        .to_return(status: 200, body: { error: "Erreur", error_description: "C'est une sacré erreur" }.to_json, headers: {})

      stub_request(:post, "https://login.microsoftonline.com/common/oauth2/v2.0/token")
        .with(
          body: { "client_id" => nil, "client_secret" => nil, "grant_type" => "refresh_token", "refresh_token" => "refresh_token" }
        )
        .to_return(status: 200, body: { access_token: "new_token" }.to_json, headers: {})

      agent.refresh_outlook_token
    end

    stub_sentry_events

    context "the agent is connected to outlook" do
      let(:agent) { create(:agent, microsoft_graph_token: "token", refresh_microsoft_graph_token: "refresh_token") }

      it "refreshes the outlook token" do
        expect(agent.microsoft_graph_token).to eq("new_token")
      end
    end

    context "the agent is not connected to outlook" do
      let(:agent) { create(:agent, email: "email@example.com") }

      it "send an error" do
        expect(agent.microsoft_graph_token).to eq(nil)

        expect(sentry_events.last.message).to eq("Error refreshing Microsoft Graph Token for email@example.com: C'est une sacré erreur")
      end
    end
  end
end
