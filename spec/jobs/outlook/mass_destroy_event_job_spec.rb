# frozen_string_literal: true

require "rails_helper"

RSpec.describe Outlook::MassDestroyEventJob, type: :job do
  let(:organisation) { create(:organisation, id: 10) }
  let(:motif) { create(:motif, name: "Super Motif", location_type: :phone) }
  # We need to create a fake agent to initialize a RDV as they have a validation on agents which prevents us to control the data in its AgentsRdv
  let(:fake_agent) { create(:agent) }
  let(:agent) { create(:agent, microsoft_graph_token: "token", refresh_microsoft_graph_token: "refresh_token") }
  let(:rdv) { create(:rdv, id: 1, motif: motif, organisation: organisation, starts_at: Time.zone.parse("2023-01-01 11h00"), agents: [fake_agent]) }
  let(:rdv2) { create(:rdv, id: 2, motif: motif, organisation: organisation, starts_at: Time.zone.parse("2023-01-01 13h00"), agents: [fake_agent]) }
  let(:rdv3) { create(:rdv, id: 3, motif: motif, organisation: organisation, starts_at: Time.zone.parse("2023-01-01 15h00"), agents: [fake_agent]) }
  let(:rdv4) { create(:rdv, id: 4, motif: motif, organisation: organisation, starts_at: Time.zone.parse("2023-01-01 17h00"), agents: [fake_agent]) }
  let!(:agents_rdv) { create(:agents_rdv, agent: agent, rdv: rdv, outlook_id: "abc", skip_outlook_create: true) }
  let!(:agents_rdv2) { create(:agents_rdv, agent: agent, rdv: rdv2, outlook_id: "def", skip_outlook_create: true) }
  let!(:agents_rdv3) { create(:agents_rdv, agent: agent, rdv: rdv3, skip_outlook_create: true) }
  let!(:agents_rdv4) { create(:agents_rdv, agent: agent, rdv: rdv4, skip_outlook_create: true) }

  before do
    stub_request(:delete, "https://graph.microsoft.com/v1.0/me/Events/abc")
      .with(headers: { "Accept" => "application/json", "Authorization" => "Bearer token", "Content-Type" => "application/json", "Expect" => "", "Return-Client-Request-Id" => "true",
                       "User-Agent" => "RDVSolidarites", })
      .to_return(status: 204, body: "", headers: {})
    stub_request(:delete, "https://graph.microsoft.com/v1.0/me/Events/def")
      .with(
        headers: { "Accept" => "application/json", "Authorization" => "Bearer token", "Content-Type" => "application/json", "Expect" => "", "Return-Client-Request-Id" => "true",
                   "User-Agent" => "RDVSolidarites", }
      )
      .to_return(status: 204, body: "", headers: {})
    described_class.perform_now(agent)
  end

  it "destroys the existing events in outlook" do
    expect(agents_rdv.reload.outlook_id).to be_nil
    expect(agents_rdv2.reload.outlook_id).to be_nil
  end

  it "unsyncs the agent" do
    expect(agent.reload.microsoft_graph_token).to eq(nil)
    expect(agent.reload.refresh_microsoft_graph_token).to eq(nil)
  end
end
