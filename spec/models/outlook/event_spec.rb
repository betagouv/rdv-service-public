# frozen_string_literal: true

describe Outlook::Event, type: :model do
  around do |example|
    perform_enqueued_jobs do
      example.run
    end
  end

  describe "refresh_token mechanism" do
    let(:organisation) { create(:organisation) }
    let(:motif) { create(:motif, name: "Super Motif", location_type: :phone) }
    # We need to create a fake agent to initialize a RDV as they have a validation on agents which prevents us to control the data in its AgentsRdv
    let(:fake_agent) { create(:agent) }
    let(:agent) { create(:agent, microsoft_graph_token: "token", refresh_microsoft_graph_token: "refresh_token") }
    let(:user) { create(:user, email: "user@example.fr", first_name: "First", last_name: "Last", organisations: [organisation]) }
    let(:rdv) { create(:rdv, users: [user], motif: motif, organisation: organisation, starts_at: Time.zone.parse("2023-01-01 11h00"), duration_in_min: 30, agents: [fake_agent]) }

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
          content: "plus d'infos dans RDV Solidarités: http://www.rdv-solidarites-test.localhost/admin/organisations/#{organisation.id}/rdvs/#{rdv.id}",
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
        attendees: [
          {
            emailAddress: {
              address: "user@example.fr",
              name: "First LAST",
            },
          },
        ],
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
      create(:agents_rdv, agent: agent, rdv: rdv)

      expect(a_request(:post,
                       "https://graph.microsoft.com/v1.0/me/Events").with(body: expected_body)).to have_been_made.twice

      expect(agent.reload.microsoft_graph_token).to eq("abc")
    end
  end
end
