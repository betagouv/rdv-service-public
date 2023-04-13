# frozen_string_literal: true

require "rails_helper"

RSpec.describe Outlook::MassCreateEventJob do
  let(:organisation) { create(:organisation) }
  let(:agent) { create(:agent) }

  let!(:future_rdv1) { create(:rdv, organisation: organisation, starts_at: 1.day.from_now, agents: [agent]) }
  let!(:future_rdv2) { create(:rdv, organisation: organisation, starts_at: 2.days.from_now, agents: [agent]) }
  let!(:recent_past_rdv) { create(:rdv, organisation: organisation, starts_at: 10.days.ago, agents: [agent]) }
  let!(:distant_past_rdv) { create(:rdv, organisation: organisation, starts_at: 200.days.ago, agents: [agent]) }

  before { allow(Outlook::SyncEventJob).to receive(:perform_later_for) }

  it "syncs future rdvs to outlook" do
    described_class.perform_now(agent)
    expect(Outlook::SyncEventJob).to have_received(:perform_later_for).with(future_rdv1.agents_rdvs.first)
    expect(Outlook::SyncEventJob).to have_received(:perform_later_for).with(future_rdv2.agents_rdvs.first)
    expect(Outlook::SyncEventJob).to have_received(:perform_later_for).with(recent_past_rdv.agents_rdvs.first)
    expect(Outlook::SyncEventJob).not_to have_received(:perform_later_for).with(distant_past_rdv.agents_rdvs.first)
  end
end
