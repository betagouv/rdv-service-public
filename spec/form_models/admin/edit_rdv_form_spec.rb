# frozen_string_literal: true

describe Admin::EditRdvForm, type: :form do
  let(:organisation) { create(:organisation) }
  let(:agent) { create(:agent) }
  let(:agent_context) { instance_double(AgentContext, agent: agent, organisation: organisation) }

  describe "#update" do
    it "updates rdv's lieu" do
      rdv = create(:rdv, agents: [agent], organisation: organisation, lieu: create(:lieu, organisation: organisation))
      new_lieu = create(:lieu, organisation: organisation)

      edit_rdv_form = described_class.new(rdv, agent_context)
      edit_rdv_form.update(lieu: new_lieu)

      expect(rdv.reload.lieu).to eq(new_lieu)
    end

    it "updates the requested rdv status" do
      rdv = create(:rdv, agents: [agent], organisation: organisation, lieu: create(:lieu, organisation: organisation))

      edit_rdv_form = described_class.new(rdv, agent_context)
      edit_rdv_form.update(status: "waiting")

      expect(rdv.reload.status).to eq("waiting")
    end

    it "set cancelled_at to nil when change status from cancel to other" do
      now = Time.zone.parse("2020-08-03 9h00")

      travel_to(now - 2.day)
      rdv = create(:rdv, cancelled_at: now - 1.day, status: "excused", starts_at: now - 2.days, agents: [agent], organisation: organisation)

      travel_to(now)

      edit_rdv_form = described_class.new(rdv, agent_context)
      edit_rdv_form.update(status: "waiting")

      expect(rdv.reload.cancelled_at).to eq(nil)
      expect(rdv.reload.status).to eq("waiting")
    end

    it "when status is excused, cancelled_at should not be nil" do
      now = Time.zone.parse("2020-08-03 9h00")
      travel_to(now - 3.days)
      rdv = create(:rdv, starts_at: now - 2.days, agents: [agent], organisation: organisation)
      travel_to(now)

      edit_rdv_form = described_class.new(rdv, agent_context)
      edit_rdv_form.update(status: "excused")

      expect(rdv.reload.cancelled_at).to eq(now)
      expect(rdv.reload.status).to eq("excused")
    end

    it "when status is excused, changing status should reset cancelled_at" do
      now = Time.zone.parse("2020-08-03 9h00")
      travel_to(now - 4.days)
      rdv = create(:rdv, cancelled_at: 2.days.ago, starts_at: now - 2.days, agents: [agent], organisation: organisation, status: "excused")
      travel_to(now)

      edit_rdv_form = described_class.new(rdv, agent_context)
      edit_rdv_form.update(status: "unknown")

      expect(rdv.reload.cancelled_at).to eq(nil)
      expect(rdv.reload.status).to eq("unknown")
    end
  end
end
