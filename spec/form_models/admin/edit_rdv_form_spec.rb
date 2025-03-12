RSpec.describe Admin::EditRdvForm, type: :form do
  let(:organisation) { create(:organisation) }
  let(:agent) { create(:agent) }
  let(:agent_context) { instance_double(AgentOrganisationContext, agent: agent, organisation: organisation) }

  before { stub_netsize_ok }

  describe "#submit" do
    it "updates rdv's lieu" do
      now = Time.zone.parse("2020-12-12 13h50")
      travel_to(now)
      rdv = create(:rdv, agents: [agent], organisation: organisation, lieu: create(:lieu, organisation: organisation))
      new_lieu = create(:lieu, organisation: organisation)

      edit_rdv_form = described_class.new(rdv, agent_context)
      edit_rdv_form.submit({ lieu: new_lieu, ignore_benign_errors: "1" })

      expect(rdv.reload.lieu).to eq(new_lieu)
    end

    it "when status is excused, cancelled_at should not be nil" do
      now = Time.zone.parse("2020-08-03 9h00")
      travel_to(now - 3.days)
      rdv = create(:rdv, starts_at: now - 2.days, agents: [agent], organisation: organisation)
      travel_to(now)

      edit_rdv_form = described_class.new(rdv, agent_context)
      edit_rdv_form.submit({ status: "excused", ignore_benign_errors: "1" })

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
      edit_rdv_form.submit({ status: "unknown", ignore_benign_errors: "1" })

      rdv.reload
      expect(rdv.cancelled_at).to be_nil
      expect(rdv.status).to eq("unknown")
    end

    context "lorsque le RDV est invalide" do
      let(:rdv) { create(:rdv, agents: [agent], organisation: organisation) }
      let(:another_rdv) { create(:rdv, agents: [agent], organisation: organisation, starts_at: rdv.starts_at) }
      let(:another_agent) { create(:agent) }

      it "on ne met pas à jour la liste des agents si l’agent n’a pas bypass l’avertissement" do
        edit_rdv_form = described_class.new(rdv, agent_context)
        edit_rdv_form.submit({ agents: [agent, another_agent] })

        expect(rdv.reload.agents).to eq([agent])
      end

      it "on met à jour la liste des agents si l’agent a bypass l’avertissement" do
        edit_rdv_form = described_class.new(rdv, agent_context)
        edit_rdv_form.submit({ agents: [agent, another_agent], ignore_benign_errors: "1" })

        expect(rdv.reload.agents).to eq([agent, another_agent])
      end
    end
  end
end
