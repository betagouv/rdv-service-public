# frozen_string_literal: true

require "rails_helper"

RSpec.describe Outlook::MassCreateEventJob, type: :job do
  let(:organisation) { create(:organisation, id: 10) }
  let(:motif) { create(:motif, name: "Super Motif", location_type: :phone) }
  let(:agent) { create(:agent) }
  let(:rdv) { build(:rdv, id: 1, motif: motif, organisation: organisation, starts_at: 1.day.from_now, agents: []) }
  let(:rdv2) { build(:rdv, id: 2, motif: motif, organisation: organisation, starts_at: 2.days.from_now, agents: []) }
  let(:rdv3) { build(:rdv, id: 3, motif: motif, organisation: organisation, starts_at: 1.day.ago, agents: []) }
  let(:rdv4) { build(:rdv, id: 4, motif: motif, organisation: organisation, starts_at: 2.days.ago, agents: []) }
  let!(:agents_rdv) { create(:agents_rdv, agent: agent, rdv: rdv, skip_outlook_create: true) }
  let!(:agents_rdv2) { create(:agents_rdv, agent: agent, rdv: rdv2, skip_outlook_create: true) }
  let!(:agents_rdv3) { create(:agents_rdv, agent: agent, rdv: rdv3, skip_outlook_create: true) }
  let!(:agents_rdv4) { create(:agents_rdv, agent: agent, rdv: rdv4, skip_outlook_create: true) }

  before do
    allow(agent).to receive_message_chain(:agents_rdvs, :future).and_return([agents_rdv, agents_rdv2])
    allow(agents_rdv).to receive(:reflect_create_in_outlook)
    allow(agents_rdv2).to receive(:reflect_create_in_outlook)
    allow(agents_rdv3).to receive(:reflect_create_in_outlook)
    allow(agents_rdv4).to receive(:reflect_create_in_outlook)

    described_class.perform_now(agent)
  end

  it "calls reflect_create_in_outlook for future rdv" do
    expect(agents_rdv).to have_received(:reflect_create_in_outlook).with(no_args).once
    expect(agents_rdv2).to have_received(:reflect_create_in_outlook).with(no_args).once
    expect(agents_rdv3).not_to have_received(:reflect_create_in_outlook)
    expect(agents_rdv4).not_to have_received(:reflect_create_in_outlook)
  end
end
