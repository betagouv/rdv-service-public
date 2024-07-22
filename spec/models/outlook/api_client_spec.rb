RSpec.describe Outlook::ApiClient do
  let(:organisation) { create(:organisation) }
  let(:expected_body) do
    {
      subject: "Super Motif",
      body: {
        contentType: "HTML",
        content: <<~HTML,
          Participants:
          <ul><li>First LAST</li></ul>
          <br />

          Plus d'infos sur <a href="http://www.rdv-solidarites-test.localhost/admin/organisations/#{organisation.id}/rdvs/#{rdv.id}">RDV Solidarités</a>:
          <br />

          Attention: ne modifiez pas cet évènement directement dans Outlook, car il ne sera pas mis à jour sur RDV Solidarités.
          Pour modifier ce rendez-vous, allez sur <a href="http://www.rdv-solidarites-test.localhost/admin/organisations/#{organisation.id}/rdvs/#{rdv.id}/edit">RDV Solidarités</a>
        HTML
      },
      start: {
        dateTime: "2023-01-01T11:00:00+01:00",
        timeZone: "Europe/Paris",
      },
      end: {
        dateTime: "2023-01-01T11:30:00+01:00",
        timeZone: "Europe/Paris",
      },
      location: {
        displayName: "Par téléphone",
      },
      attendees: [],
      transactionId: "agents_rdv-#{agents_rdv.id}",
    }
  end
  let(:motif) { create(:motif, name: "Super Motif", location_type: :phone) }
  let(:agent) { create(:agent, microsoft_graph_token: "token", refresh_microsoft_graph_token: "refresh_token") }
  let(:user) { create(:user, email: "user@example.fr", first_name: "First", last_name: "Last", organisations: [organisation]) }
  let(:rdv) { create(:rdv, users: [user], motif: motif, organisation: organisation, starts_at: Time.zone.parse("2023-01-01 11h00"), duration_in_min: 30, agents: [agent]) }
  let(:agents_rdv) { rdv.agents_rdvs.first }

  before do
    allow(ENV).to receive(:fetch).with("AZURE_APPLICATION_CLIENT_ID", nil).and_return("fake_client_id")
    allow(ENV).to receive(:fetch).with("AZURE_APPLICATION_CLIENT_SECRET", nil).and_return("fake_client_secret")
  end

  context "when a call fails" do
    before do
      stub_request(:post, "https://graph.microsoft.com/v1.0/me/Events")
        .to_return(
          status: 403,
          body: {
            error: {
              code: "ErrorAccountSuspend",
              message: "Account suspended. Follow the instructions in your Inbox to verify your account.",
            },
          }.to_json,
          headers: {}
        )
    end

    it "raises an error so that the job around it is retried later" do
      expect do
        described_class.new(agent).create_event!(expected_body)
      end.to raise_error(Outlook::ApiClient::ApiError, "Account suspended. Follow the instructions in your Inbox to verify your account.")
    end

    context "when the error is permanent" do
      before do
        stub_request(:delete, "https://graph.microsoft.com/v1.0/me/Events/abc")
          .to_return(
            status: 404,
            body: {
              error: {
                code: "ErrorItemNotFound", # this error is permanent
                message: "The specified object was not found in the store",
              },
            }.to_json,
            headers: {}
          )
      end

      it "logs the error but does not warn Sentry" do
        allow(Rails.logger).to receive(:error)
        described_class.new(agent).delete_event!("abc")

        expect(Rails.logger).to have_received(:error).with("Outlook error while deleting event: The specified object was not found in the store")
        expect(sentry_events).to be_empty
      end
    end

    context "when the request times out" do
      before do
        stub_request(:post, "https://graph.microsoft.com/v1.0/me/Events").to_timeout
      end

      it "raises an exception" do
        expect do
          described_class.new(agent).create_event!(expected_body)
        end.to raise_error(Typhoeus::Errors::TimeoutError)
      end
    end
  end

  describe "when the token needs to be refreshed" do
    let(:expected_headers) do
      {
        "Accept" => "application/json",
        "Authorization" => "Bearer token",
        "Content-Type" => "application/json",
        "Expect" => "",
        "Return-Client-Request-Id" => "true",
        "User-Agent" => "RDVSolidarites",
      }
    end

    let(:expected_updated_headers) do
      {
        "Accept" => "application/json",
        "Authorization" => "Bearer abc",
        "Content-Type" => "application/json",
        "Expect" => "",
        "Return-Client-Request-Id" => "true",
        "User-Agent" => "RDVSolidarites",
      }
    end

    before do
      stub_request(:post, "https://graph.microsoft.com/v1.0/me/Events")
        .with(body: expected_body, headers: expected_headers)
        .to_return(status: 401, body: { error: "wrong token" }.to_json, headers: {})
    end

    context "when the token refresh works" do
      before do
        stub_request(:post, "https://login.microsoftonline.com/common/oauth2/v2.0/token")
          .with(
            body: { "client_id" => "fake_client_id", "client_secret" => "fake_client_secret", "grant_type" => "refresh_token", "refresh_token" => "refresh_token" }
          )
          .to_return(status: 200, body: { access_token: "abc" }.to_json, headers: {})

        stub_request(:post, "https://graph.microsoft.com/v1.0/me/Events")
          .with(body: expected_body, headers: expected_updated_headers)
          .to_return(status: 200, body: { id: "event_id" }.to_json, headers: {})
      end

      it "refreshes it and retries, and saves the refresh token on the agent" do
        described_class.new(agent).create_event!(expected_body)

        expect(a_request(:post,
                         "https://graph.microsoft.com/v1.0/me/Events").with(body: expected_body)).to have_been_made.twice

        expect(agent.reload.microsoft_graph_token).to eq("abc")
      end
    end

    context "when the token refresh fails" do
      before do
        stub_request(:post, "https://login.microsoftonline.com/common/oauth2/v2.0/token")
          .with(
            body: { "client_id" => "fake_client_id", "client_secret" => "fake_client_secret", "grant_type" => "refresh_token", "refresh_token" => "refresh_token" }
          )
          .to_return(status: 500, body: { error: "Unknwon error" }.to_json, headers: {})
      end

      it "raises an error" do
        expect { described_class.new(agent).create_event!(expected_body) }.to raise_error(Outlook::ApiClient::RefreshTokenError, "Unknwon error")
      end
    end
  end
end
