class DummyForm
  include ActiveModel::Model
  include Admin::RdvFormConcern

  def initialize(rdv, agent)
    @rdv = rdv
    @agent = agent
  end

  def agent_context; end
end

describe Admin::RdvFormConcern, type: :form do
  subject { DummyForm.new(rdv, agent_author) }
  let!(:agent_author) { create(:agent, first_name: "Poney", last_name: "FOU") }
  let(:rdv_start_coherence) { instance_double(RdvStartCoherence) }
  let(:rdvs_overlapping) { instance_double(RdvsOverlapping) }
  before do
    allow(subject).to receive(:agent_context).and_return(agent_context)
    allow(RdvStartCoherence).to receive(:new).with(rdv).and_return(rdv_start_coherence)
    allow(RdvsOverlapping).to receive(:new).with(rdv).and_return(rdvs_overlapping)
  end
  let(:agent_context) { instance_double(AgentContext, agent: agent_author, organisation: build(:organisation)) }

  describe "validations" do
    context "rdv is not valid" do
      let(:rdv) { build(:rdv) }
      before do
        expect(rdv).to receive(:valid?).and_return(false)
        expect(rdv).to receive(:errors).and_return([[:base, "not cool"]])
      end

      it "should not be valid" do
        expect(subject.valid?).to eq false
        expect(subject.errors[:base]).to include "not cool"
      end
    end

    context "rdv is valid + no rdvs ending shortly before" do
      let(:rdv) { build(:rdv) }
      before do
        expect(rdv).to receive(:valid?).and_return(true)
        allow(rdv_start_coherence).to receive(:rdvs_ending_shortly_before?).and_return(false)
        allow(rdvs_overlapping).to receive(:rdvs_overlapping_rdv?).and_return(false)
      end

      it "should be valid" do
        expect(subject.valid?).to eq true
      end
    end

    context "rdv is valid but there is another rdv ending shortly before" do
      let!(:agent_new_rdv) { create(:agent) }
      let(:rdv) { build(:rdv, agents: [agent_new_rdv]) }
      let!(:rdv2) { create(:rdv, agents: [agent_new_rdv]) }

      before do
        allow(rdv).to receive(:valid?).and_return(true)
        allow(rdv_start_coherence).to receive(:rdvs_ending_shortly_before?).and_return(true)
        allow(rdv_start_coherence).to receive(:rdvs_ending_shortly_before).and_return([rdv2])
        allow(rdvs_overlapping).to receive(:rdvs_overlapping_rdv?).and_return(false)
        allow(RdvEndingShortlyBeforePresenter).to receive(:new)
          .with(rdv: rdv2, agent: agent_new_rdv, rdv_context: rdv, agent_context: agent_context)
          .and_return(instance_double(RdvEndingShortlyBeforePresenter, warning_message: "alerte RDV proche !"))
      end

      it "should not be valid" do
        expect(subject.valid?).to eq false
        expect(subject.errors).not_to be_empty
      end

      it "should include warnings" do
        subject.valid?
        expect(subject.warnings_need_confirmation?).to eq true
        expect(subject.warnings).not_to be_empty
        expect(subject.warnings[:base]).to include("alerte RDV proche !")
      end
    end

    context "rdv is valid but there are multiple other RDVs ending shortly before" do
      let!(:agent_giono) { build(:agent, first_name: "Jean", last_name: "GIONO") }
      let!(:agent_maceo) { build(:agent, first_name: "Maceo", last_name: "PARKER") }
      let(:rdv) { build(:rdv, agents: [agent_giono, agent_maceo], starts_at: Date.today.next_week(:monday).in_time_zone + 16.hours) }
      let!(:rdvs_giono) { build_list(:rdv, 2, agents: [agent_giono]) }
      let!(:rdvs_maceo) { build_list(:rdv, 2, agents: [agent_maceo]) }

      before do
        allow(rdv).to receive(:valid?).and_return(true)
        allow(rdv_start_coherence).to receive(:rdvs_ending_shortly_before?).and_return(true)
        allow(rdv_start_coherence).to receive(:rdvs_ending_shortly_before)
          .and_return(rdvs_giono + rdvs_maceo) # this is considered sorted on ends_at ASC
        allow(rdvs_overlapping).to receive(:rdvs_overlapping_rdv?).and_return(false)
        allow(RdvEndingShortlyBeforePresenter).to receive(:new)
          .with(rdv: rdvs_giono.last, agent: agent_giono, rdv_context: rdv, agent_context: agent_context)
          .and_return(instance_double(RdvEndingShortlyBeforePresenter, warning_message: "alerte RDV Giono !"))
        allow(RdvEndingShortlyBeforePresenter).to receive(:new)
          .with(rdv: rdvs_maceo.last, agent: agent_maceo, rdv_context: rdv, agent_context: agent_context)
          .and_return(instance_double(RdvEndingShortlyBeforePresenter, warning_message: "alerte RDV Maceo !"))
      end

      it "should not be valid" do
        expect(subject.valid?).to eq false
        expect(subject.errors).not_to be_empty
      end

      it "should include warnings" do
        subject.valid?
        expect(subject.warnings_need_confirmation?).to eq true
        expect(subject.warnings).not_to be_empty
        expect(subject.warnings[:base]).to match_array(["alerte RDV Giono !", "alerte RDV Maceo !"])
      end
    end

    context "rdv is valid but there are an other RDV that start before this ending" do
      let!(:agent_new_rdv) { create(:agent) }
      let(:rdv) { build(:rdv, agents: [agent_new_rdv]) }
      let!(:rdv2) { create(:rdv, agents: [agent_new_rdv]) }

      before do
        allow(rdv).to receive(:valid?).and_return(true)
        allow(rdv_start_coherence).to receive(:rdvs_ending_shortly_before?).and_return(false)
        allow(rdvs_overlapping).to receive(:rdvs_overlapping_rdv?).and_return(true)
        allow(rdvs_overlapping).to receive(:rdvs_overlapping_rdv).and_return([rdv2])
        allow(RdvsOverlappingRdvPresenter).to receive(:new)
          .with(rdv: rdv2, agent: agent_new_rdv, rdv_context: rdv, agent_context: agent_context)
          .and_return(instance_double(RdvsOverlappingRdvPresenter, warning_message: "alerte RDV se cheveauchant !"))
      end

      it "should not be valid" do
        expect(subject.valid?).to eq false
        expect(subject.errors).not_to be_empty
      end

      it "should include warnings" do
        subject.valid?
        expect(subject.warnings_need_confirmation?).to eq true
        expect(subject.warnings).not_to be_empty
        expect(subject.warnings[:base]).to include("alerte RDV se cheveauchant !")
      end
    end
  end
end
