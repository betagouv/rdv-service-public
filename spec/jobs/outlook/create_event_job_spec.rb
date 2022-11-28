# frozen_string_literal: true

require "rails_helper"

RSpec.describe Outlook::CreateEventJob, type: :job do
  let(:organisation) { create(:organisation, id: 10) }
  let(:motif) { create(:motif, name: "Super Motif", location_type: :phone) }
  let(:agent) { create(:agent) }
  let(:rdv) { build(:rdv, id: 20, motif: motif, organisation: organisation, starts_at: Time.zone.parse("2023-01-01 11h00"), duration_in_min: 30, agents: []) }
  let!(:agents_rdv) { create(:agents_rdv, id: 12, agent: agent, rdv: rdv, skip_outlook_create: true) }

  context "when the event is created" do
    before do
      stub_request(:post, "https://login.microsoftonline.com/common/oauth2/v2.0/token")
        .to_return(status: 200, body: { access_token: "token" }.to_json, headers: {})
      stub_request(:post, "https://graph.microsoft.com/v1.0/me/Events")
        .with(
          body: "{\"subject\":\"Super Motif\",\"body\":{\"contentType\":\"HTML\",\"content\":\"plus d'infos dans RDV Solidarités: http://www.rdv-solidarites-test.localhost/admin/organisations/10/rdvs/20\"},\"start\":{\"dateTime\":\"2023-01-01T11:00:00+01:00\",\"timeZone\":\"Europe/Paris\"},\"end\":{\"dateTime\":\"2023-01-01T11:30:00+01:00\",\"timeZone\":\"Europe/Paris\"},\"location\":{\"displayName\":\"Par téléphone\"}}",
          headers: { "Accept" => "application/json", "Authorization" => "Bearer token", "Content-Type" => "application/json", "Expect" => "", "Return-Client-Request-Id" => "true",
                     "User-Agent" => "RDVSolidarites", }
        )
        .to_return(status: 200, body: { id: "event_id" }.to_json, headers: {})

      described_class.perform_now(agents_rdv)
    end

    it "update the outlook_id of the agents_rdv" do
      expect(agent.reload.microsoft_graph_token).to eq("token")
      expect(agents_rdv.outlook_id).to eq("event_id")
    end
  end

  context "when the event cannot be created" do
    before do
      stub_request(:post, "https://login.microsoftonline.com/common/oauth2/v2.0/token")
        .to_return(status: 200, body: { access_token: "token" }.to_json, headers: {})
      stub_request(:post, "https://graph.microsoft.com/v1.0/me/Events")
        .with(
          body: "{\"subject\":\"Super Motif\",\"body\":{\"contentType\":\"HTML\",\"content\":\"plus d'infos dans RDV Solidarités: http://www.rdv-solidarites-test.localhost/admin/organisations/10/rdvs/20\"},\"start\":{\"dateTime\":\"2023-01-01T11:00:00+01:00\",\"timeZone\":\"Europe/Paris\"},\"end\":{\"dateTime\":\"2023-01-01T11:30:00+01:00\",\"timeZone\":\"Europe/Paris\"},\"location\":{\"displayName\":\"Par téléphone\"}}",
          headers: { "Accept" => "application/json", "Authorization" => "Bearer token", "Content-Type" => "application/json", "Expect" => "", "Return-Client-Request-Id" => "true",
                     "User-Agent" => "RDVSolidarites", }
        )
        .to_return(status: 404, body: { error: { code: "TerribleError", message: "Quelle terrible erreur" } }.to_json, headers: {})

      allow(Sentry).to receive(:capture_message)

      described_class.perform_now(agents_rdv)
    end

    it "sends the error to Sentry" do
      expect(agents_rdv.outlook_id).to eq(nil)

      expect(Sentry).to have_received(:capture_message).with("Outlook API error for AgentsRdv 12: Quelle terrible erreur")
    end
  end
end
