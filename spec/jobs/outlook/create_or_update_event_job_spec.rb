# frozen_string_literal: true

require "rails_helper"

# TODO: add a spec for the logic when choosing the proper update
RSpec.describe Outlook::CreateOrUpdateEventJob, type: :job do
  let(:organisation) { create(:organisation) }
  let(:motif) { create(:motif, name: "Super Motif", location_type: :phone) }
  # We need to create a fake agent to initialize a RDV as they have a validation on agents which prevents us to control the data in its AgentsRdv
  let(:fake_agent) { create(:agent) }
  let(:agent) { create(:agent, microsoft_graph_token: "token") }
  let(:user) { create(:user, email: "user@example.fr", first_name: "First", last_name: "Last", organisations: [organisation]) }
  let(:rdv) { create(:rdv, users: [user], motif: motif, organisation: organisation, starts_at: Time.zone.parse("2023-01-01 11h00"), duration_in_min: 30, agents: [fake_agent]) }
  let!(:agents_rdv) { create(:agents_rdv, agent: agent, rdv: rdv) }

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
  let(:expected_body) do
    {
      subject: "Super Motif",
      body: {
        contentType: "HTML",
        content: expected_description,
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
  let(:expected_description) do
    <<~HTML
      Participants:
      <ul><li>First LAST</li></ul>
      <br />

      Plus d'infos sur <a href="http://www.rdv-solidarites-test.localhost/admin/organisations/#{organisation.id}/rdvs/#{rdv.id}">RDV Solidarités</a>:
      <br />

      Attention: ne modifiez pas cet évènement directement dans Outlook, car il ne sera pas mis à jour sur RDV Solidarités.
      Pour modifier ce rendez-vous, allez sur <a href="http://www.rdv-solidarites-test.localhost/admin/organisations/#{organisation.id}/rdvs/#{rdv.id}/edit">RDV Solidarités</a>
    HTML
  end

  context "when the event is created" do
    before do
      stub_request(:post, "https://graph.microsoft.com/v1.0/me/Events")
        .with(
          body: expected_body,
          headers: expected_headers
        )
        .to_return(status: 200, body: { id: "event_id" }.to_json, headers: {})

      described_class.perform_now(agents_rdv)
    end

    it "update the outlook_id of the agents_rdv" do
      expect(agents_rdv.outlook_id).to eq("event_id")
    end
  end

  context "when the event cannot be created" do
  end
end
