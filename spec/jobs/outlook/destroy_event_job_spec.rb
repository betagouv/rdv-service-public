# frozen_string_literal: true

require "rails_helper"

RSpec.describe Outlook::DestroyEventJob, type: :job do
  let(:organisation) { create(:organisation, id: 10) }
  let(:motif) { create(:motif, name: "Super Motif", location_type: :phone) }
  # We need to create a fake agent to initialize a RDV as they have a validation on agents which prevents us to control the data in its AgentsRdv
  let(:fake_agent) { create(:agent) }
  let(:agent) { create(:agent, microsoft_graph_token: "token") }
  let(:rdv) { create(:rdv, id: 20, motif: motif, organisation: organisation, starts_at: Time.zone.parse("2023-01-01 11h00"), duration_in_min: 30, agents: [fake_agent]) }
  let!(:agents_rdv) { create(:agents_rdv, id: 12, rdv: rdv, agent: agent, outlook_id: "super_id") }

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

  stub_sentry_events

  context "when the event is destroyed" do
    before do
      stub_request(:delete, "https://graph.microsoft.com/v1.0/me/Events/super_id")
        .with(headers: expected_headers)
        .to_return(status: 204, body: "", headers: {})

      described_class.perform_now("super_id", agent)
    end

    it "updates the outlook_id" do
      expect(agents_rdv.reload.outlook_id).to eq(nil)

      expect(sentry_events).to be_empty
    end
  end

  context "when the event cannot be destroyed" do
    before do
      stub_request(:delete, "https://graph.microsoft.com/v1.0/me/Events/super_id")
        .with(headers: expected_headers)
        .to_return(status: 404, body: { error: { code: "TerribleError", message: "Quelle terrible erreur" } }.to_json, headers: {})

      described_class.perform_now("super_id", agent)
    end

    it "does not update the outlook_id" do
      expect(agents_rdv.reload.outlook_id).to eq("super_id")

      expect(sentry_events.last.message).to eq("Outlook API error for AgentsRdv super_id: Quelle terrible erreur")
    end
  end
end
