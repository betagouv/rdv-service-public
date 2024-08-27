RSpec.describe Admin::RdvFormConcern, type: :form do
  subject(:form) { dummy_form_class.new(rdv, agent_author) }

  let(:dummy_form_class) do
    Class.new do
      include ActiveModel::Model
      include Admin::RdvFormConcern

      def initialize(rdv, agent)
        @rdv = rdv
        @agent = agent
      end

      def save
        valid? && rdv.save
      end

      attr_accessor :agent_context
    end
  end

  let(:now) { Time.zone.parse("2021-11-23 11:00") }
  let!(:agent_author) { create(:agent, first_name: "Poney", last_name: "FOU") }
  let(:agent_context) { instance_double(AgentOrganisationContext, agent: agent_author, organisation: build(:organisation)) }
  let(:rdv_start_coherence) { instance_double(RdvStartCoherence) }
  let(:rdvs_overlapping) { instance_double(RdvsOverlapping) }

  before do
    travel_to(now)
    form.agent_context = agent_context
    allow(RdvStartCoherence).to receive(:new).with(rdv).and_return(rdv_start_coherence)
    allow(RdvsOverlapping).to receive(:new).with(rdv).and_return(rdvs_overlapping)
  end

  describe "validations" do
    context "rdv is not valid" do
      let(:rdv) { build(:rdv, starts_at: now) }

      before do
        allow(rdv).to receive(:validate) { rdv.errors.add(:base, "not cool") }
        allow(rdv_start_coherence).to receive(:rdvs_ending_shortly_before?).and_return(false)
        allow(rdvs_overlapping).to receive(:rdvs_overlapping_rdv?).and_return(false)
      end

      it "is not valid" do
        expect(form.valid?).to eq false
        expect(form.errors[:base]).to include "not cool"
      end
    end

    context "rdv is valid + no rdvs ending shortly before" do
      let(:rdv) { build(:rdv) }

      before do
        allow(rdv).to receive(:valid?).and_return(true)
        allow(rdv_start_coherence).to receive(:rdvs_ending_shortly_before?).and_return(false)
        allow(rdvs_overlapping).to receive(:rdvs_overlapping_rdv?).and_return(false)
      end

      it "is valid" do
        expect(form.valid?).to eq true
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

      it "is not valid" do
        expect(form.valid?).to eq false
        expect(form.errors).not_to be_empty
      end

      it "includes warnings" do
        form.valid?
        expect(form.errors_are_all_benign?).to eq true
        expect(form.benign_errors).not_to be_empty
        expect(form.benign_errors).to include("alerte RDV proche !")
      end
    end

    context "rdv is valid but there are multiple other RDVs ending shortly before" do
      let(:now) { Time.zone.parse("2021-12-13 10:45") }
      let!(:agent_giono) { build(:agent, first_name: "Jean", last_name: "GIONO") }
      let!(:agent_maceo) { build(:agent, first_name: "Maceo", last_name: "PARKER") }
      let(:rdv) { build(:rdv, agents: [agent_giono, agent_maceo], starts_at: now + 1.week) }
      let!(:rdvs_giono) { build_list(:rdv, 2, agents: [agent_giono]) }
      let!(:rdvs_maceo) { build_list(:rdv, 2, agents: [agent_maceo]) }

      before do
        travel_to(now)
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

      it "is not valid" do
        expect(form.valid?).to eq false
        expect(form.errors).not_to be_empty
      end

      it "includes warnings" do
        form.valid?
        expect(form.errors_are_all_benign?).to eq true
        expect(form.benign_errors).not_to be_empty
        expect(form.benign_errors).to contain_exactly("alerte RDV Giono !", "alerte RDV Maceo !")
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
          .and_return(instance_double(RdvsOverlappingRdvPresenter, warning_message: "alerte RDV se chevauchant !"))
      end

      it "is not valid" do
        expect(form.valid?).to eq false
        expect(form.errors).not_to be_empty
      end

      it "includes warnings" do
        form.valid?
        expect(form.errors_are_all_benign?).to eq true
        expect(form.benign_errors).not_to be_empty
        expect(form.benign_errors).to include("alerte RDV se chevauchant !")
      end
    end
  end

  describe "#check_duplicates" do
    let(:rdv) { create(:rdv) }

    it "do nothing when no other RDV" do
      form.check_duplicates
      expect(rdv.errors).to be_empty
    end

    it "add an error if RDV already exist with same motif, user and agent" do
      create(:rdv,
             motif: rdv.motif,
             users: rdv.users,
             agents: rdv.agents,
             organisation: rdv.organisation,
             lieu: rdv.lieu,
             starts_at: rdv.starts_at,
             ends_at: rdv.ends_at)

      form.check_duplicates
      expect(rdv.errors.full_messages).to eq(["Il existe déjà un RDV au même moment, au même lieu, pour le même motif, avec les mêmes participant⋅es"])
    end

    it "return nothing if existing RDV is for an other users and other agents" do
      create(:rdv,
             motif: rdv.motif,
             users: [create(:user)],
             agents: [create(:agent, organisations: [rdv.organisation])],
             organisation: rdv.organisation,
             lieu: rdv.lieu,
             starts_at: rdv.starts_at,
             ends_at: rdv.ends_at)

      form.check_duplicates
      expect(rdv.errors).to be_empty
    end
  end
end
