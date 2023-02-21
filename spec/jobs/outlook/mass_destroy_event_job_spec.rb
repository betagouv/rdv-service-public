# frozen_string_literal: true

require "rails_helper"

RSpec.describe Outlook::MassDestroyEventJob, type: :job do
  let(:organisation) { create(:organisation) }
  let(:motif) { create(:motif, name: "Super Motif", location_type: :phone) }
  # We need to create a fake agent to initialize a RDV as they have a validation on agents which prevents us to control the data in its AgentsRdv
  let(:fake_agent) { create(:agent) }
  let(:agent) { create(:agent, microsoft_graph_token: "token", refresh_microsoft_graph_token: "refresh_token") }
  let(:rdv) { create(:rdv, motif: motif, organisation: organisation, starts_at: Time.zone.parse("2023-01-01 11h00"), agents: [fake_agent]) }
  let(:rdv2) { create(:rdv, motif: motif, organisation: organisation, starts_at: Time.zone.parse("2023-01-01 13h00"), agents: [fake_agent]) }
  let(:rdv3) { create(:rdv, motif: motif, organisation: organisation, starts_at: Time.zone.parse("2023-01-01 15h00"), agents: [fake_agent]) }
  let(:rdv4) { create(:rdv, motif: motif, organisation: organisation, starts_at: Time.zone.parse("2023-01-01 17h00"), agents: [fake_agent]) }
  let!(:agents_rdv) { create(:agents_rdv, agent: agent, rdv: rdv, outlook_id: "abc") }
  let!(:agents_rdv2) { create(:agents_rdv, agent: agent, rdv: rdv2, outlook_id: "def") }
  let!(:agents_rdv3) { create(:agents_rdv, agent: agent, rdv: rdv3) }
  let!(:agents_rdv4) { create(:agents_rdv, agent: agent, rdv: rdv4) }

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

  context "when the events are deleted successfully" do
    before do
      stub_request(:delete, "https://graph.microsoft.com/v1.0/me/Events/abc")
        .with(headers: expected_headers)
        .to_return(status: 204, body: "", headers: {})
      stub_request(:delete, "https://graph.microsoft.com/v1.0/me/Events/def")
        .with(headers: expected_headers)
        .to_return(status: 204, body: "", headers: {})
    end

    it "destroys the existing events in outlook" do
      expect do
        described_class.perform_now(agent)
      end.to change { agents_rdv.reload.outlook_id }.to(nil)
        .and change { agents_rdv2.reload.outlook_id }.to(nil)
    end

    it "unsyncs the agent" do
      expect do
        described_class.perform_now(agent)
      end.to change { agent.reload.microsoft_graph_token }.to(nil)
        .and change { agent.reload.refresh_microsoft_graph_token }.to(nil)
    end
  end

  context "when there is an error while destroying one of the events" do
    before do
      stub_request(:delete, "https://graph.microsoft.com/v1.0/me/Events/abc")
        .with(headers: expected_headers)
        .to_return(status: 204, body: "", headers: {})
      stub_request(:delete, "https://graph.microsoft.com/v1.0/me/Events/def")
        .with(headers: expected_headers)
        .to_return(
          status: 403,
          body: {
            "error" => {
              "message" => "The specified object was not found in the store.",
            },
          }.to_json,
          headers: {}
        )
    end

    it "unsyncs the agent" do
      expect do
        described_class.perform_now(agent)
      end.to change { agent.reload.microsoft_graph_token }.to(nil)
        .and change { agent.reload.refresh_microsoft_graph_token }.to(nil)
    end
  end
end
