# frozen_string_literal: true

describe Outlook::Event, type: :model do
  let(:organisation) { create(:organisation) }
  let(:motif) { create(:motif, name: "Super Motif", location_type: :phone) }
  let(:agent) { create(:agent, microsoft_graph_token: "token", refresh_microsoft_graph_token: "refresh_token") }
  let(:user) { create(:user, email: "user@example.fr", first_name: "First", last_name: "Last", organisations: [organisation]) }
  let(:rdv) { create(:rdv, users: [user], motif: motif, organisation: organisation, starts_at: Time.zone.parse("2023-01-01 11h00"), duration_in_min: 30, agents: [agent]) }
  let(:agents_rdv) { rdv.agents_rdvs.first }

  describe "#create" do
    context "when the call fails" do
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
          described_class.new(agents_rdv: agents_rdv).create
        end.to raise_error("Outlook API error for AgentsRdv #{agents_rdv.id}: Account suspended. Follow the instructions in your Inbox to verify your account.")
      end
    end
  end

  describe "refresh_token mechanism" do
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

    before do
      stub_request(:post, "https://graph.microsoft.com/v1.0/me/Events")
        .with(body: expected_body, headers: expected_headers)
        .to_return(status: 401, body: { error: "wrong token" }.to_json, headers: {})

      stub_request(:post, "https://login.microsoftonline.com/common/oauth2/v2.0/token")
        .with(
          body: { "client_id" => nil, "client_secret" => nil, "grant_type" => "refresh_token", "refresh_token" => "refresh_token" }
        )
        .to_return(status: 200, body: { access_token: "abc" }.to_json, headers: {})

      stub_request(:post, "https://graph.microsoft.com/v1.0/me/Events")
        .with(body: expected_body, headers: expected_updated_headers)
        .to_return(status: 200, body: { id: "event_id" }.to_json, headers: {})
    end

    it "refreshes the Outlook::User's token when needed" do
      described_class.new(agents_rdv: agents_rdv).create

      expect(a_request(:post,
                       "https://graph.microsoft.com/v1.0/me/Events").with(body: expected_body)).to have_been_made.twice

      expect(agent.reload.microsoft_graph_token).to eq("abc")
    end
  end
end
