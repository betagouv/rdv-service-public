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

    context "ajout d’un agent à un RDV avec une erreur contournable" do
      subject do
        described_class.new(rdv2, agent_context).submit(attributes)
        rdv2.reload.agents.map(&:full_name).sort.to_sentence
      end

      let!(:organisation) { create(:organisation) }
      let!(:agent_mayra) { create(:agent, first_name: "Mayra", last_name: "Castello", basic_role_in_organisations: [organisation]) }
      let!(:agent_stefan) { create(:agent, first_name: "Stefan", last_name: "Hoyt", basic_role_in_organisations: [organisation]) }
      let(:agent_context) { instance_double(AgentOrganisationContext, agent: agent_mayra, organisation:) }
      let!(:rdv1) { create(:rdv, agents: [agent_mayra], organisation:, starts_at: Time.zone.parse("2025-04-28 10:30")) }
      let!(:rdv2) { create(:rdv, agents: [agent_mayra], organisation:, starts_at: Time.zone.parse("2025-04-29 18:00")) }
      let(:base_attributes) do
        {
          starts_at: Time.zone.parse("2025-04-28 10:30"), # le même horaire que rdv1, déclenche une erreur contournable
          agent_ids: [agent_mayra.id, agent_stefan.id],
        }
      end

      before { travel_to Time.zone.parse("2025-04-24 10:00") }

      context "l’avertissement est contourné" do
        let(:attributes) { base_attributes.merge(ignore_benign_errors: "1") }

        it { is_expected.to eq("Mayra CASTELLO et Stefan HOYT") }
      end

      context "l’avertissement n’est pas contourné" do
        let(:attributes) { base_attributes }

        it { is_expected.to eq("Mayra CASTELLO") }
      end
    end
  end
end
