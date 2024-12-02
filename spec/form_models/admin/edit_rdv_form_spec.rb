RSpec.describe Admin::EditRdvForm, type: :form do
  let(:organisation) { create(:organisation) }
  let(:agent) { create(:agent) }
  let(:agent_context) { instance_double(AgentOrganisationContext, agent: agent, organisation: organisation) }

  before { stub_netsize_ok }

  describe "#update" do
    it "updates rdv's lieu" do
      now = Time.zone.parse("2020-12-12 13h50")
      travel_to(now)
      rdv = create(:rdv, agents: [agent], organisation: organisation, lieu: create(:lieu, organisation: organisation))
      new_lieu = create(:lieu, organisation: organisation)

      edit_rdv_form = described_class.new(rdv, agent_context)
      edit_rdv_form.update(lieu: new_lieu, ignore_benign_errors: "1")

      expect(rdv.reload.lieu).to eq(new_lieu)
    end

    it "when status is excused, cancelled_at should not be nil" do
      now = Time.zone.parse("2020-08-03 9h00")
      travel_to(now - 3.days)
      rdv = create(:rdv, starts_at: now - 2.days, agents: [agent], organisation: organisation)
      travel_to(now)

      edit_rdv_form = described_class.new(rdv, agent_context)
      edit_rdv_form.update(status: "excused", ignore_benign_errors: "1")

      rdv.reload
      expect(rdv.cancelled_at).to eq(now)
      expect(rdv.status).to eq("excused")
    end

    it "when status is excused, changing status should reset cancelled_at" do
      now = Time.zone.parse("2020-08-03 9h00")
      travel_to(now - 4.days)
      rdv = create(:rdv, cancelled_at: 2.days.ago, starts_at: now - 2.days, agents: [agent], organisation: organisation, status: "excused")
      travel_to(now)

      edit_rdv_form = described_class.new(rdv, agent_context)
      edit_rdv_form.update(status: "unknown", ignore_benign_errors: "1")

      rdv.reload
      expect(rdv.cancelled_at).to be_nil
      expect(rdv.status).to eq("unknown")
    end
  end
end
