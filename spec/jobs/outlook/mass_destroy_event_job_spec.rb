require "rails_helper"

RSpec.describe Outlook::MassCreateEventJob, type: :job do
  let(:organisation) { create(:organisation, id: 10) }
  let(:motif) { create(:motif, name: "Super Motif", location_type: :phone)}
  let(:agent) { create(:agent, microsoft_graph_token: "token", refresh_microsoft_graph_token: "refresh_token") }
  let(:rdv) { build(:rdv, id: 1, motif: motif, organisation: organisation, starts_at: Time.zone.parse("2023-01-01 11h00"), agents: [])}
  let(:rdv2) { build(:rdv, id: 2, motif: motif, organisation: organisation, starts_at: Time.zone.parse("2023-01-01 13h00"), agents: [])}
  let(:rdv3) { build(:rdv, id: 3, motif: motif, organisation: organisation, starts_at: Time.zone.parse("2023-01-01 15h00"), agents: [])}
  let(:rdv4) { build(:rdv, id: 4, motif: motif, organisation: organisation, starts_at: Time.zone.parse("2023-01-01 17h00"), agents: [])}
  let!(:agents_rdv) { create(:agents_rdv, agent: agent, rdv: rdv, outlook_id: "abc", skip_outlook_create: true) }
  let!(:agents_rdv2) { create(:agents_rdv, agent: agent, rdv: rdv2, outlook_id: "def", skip_outlook_create: true) }
  let!(:agents_rdv3) { create(:agents_rdv, agent: agent, rdv: rdv3, skip_outlook_create: true) }
  let!(:agents_rdv4) { create(:agents_rdv, agent: agent, rdv: rdv4, skip_outlook_create: true) }

  before do
    allow(Outlook::DestroyEventJob).to receive(:perform_now)

    Outlook::MassDestroyEventJob.perform_now(agent)
  end

  it "calls DestroyEventJob for existing event in outlook" do
    expect(Outlook::DestroyEventJob).to have_received(:perform_now).with(agents_rdv).once
    expect(Outlook::DestroyEventJob).to have_received(:perform_now).with(agents_rdv2).once
    expect(Outlook::DestroyEventJob).not_to have_received(:perform_now).with(agents_rdv3)
    expect(Outlook::DestroyEventJob).not_to have_received(:perform_now).with(agents_rdv4)
  end

  it "unsyncs the agent" do
    expect(agent.reload.microsoft_graph_token).to eq(nil)
    expect(agent.reload.refresh_microsoft_graph_token).to eq(nil)
  end
end
