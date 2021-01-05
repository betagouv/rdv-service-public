describe Motif, type: :model do
  it "have a valid factory" do
    expect(build(:motif)).to be_valid
  end

  it "invalid without #RRGGBB format's color" do
    expect(build(:motif, color: "vert")).to be_invalid
    expect(build(:motif, color: "002233")).to be_invalid
    expect(build(:motif, color: "#002233")).to be_valid
  end

  let!(:organisation) { create(:organisation) }
  let(:motif) { create(:motif, organisation: organisation) }
  let(:secretariat) { create(:service, :secretariat) }
  let(:motif_with_rdv) { create(:motif, :with_rdvs, organisation: organisation) }

  describe ".create when associated with secretariat" do
    let(:motif) { build(:motif, service: secretariat, organisation: organisation) }
    it {
      expect(motif.valid?).to be false
    }
  end

  describe "#soft_delete" do
    before do
      freeze_time
      @delation_time = Time.current
      motif.soft_delete
      motif_with_rdv.soft_delete
    end

    it "doesn't delete the motif with rdvs" do
      expect(Motif.all).to eq [motif_with_rdv]
      expect(motif_with_rdv.reload.deleted_at).to eq @delation_time
    end
  end

  describe "#available_motifs_for_organisation_and_agent" do
    let(:service) { create(:service) }
    let!(:motif) { create(:motif, service: service, organisation: organisation) }
    let!(:motif2) { create(:motif, service: service, organisation: organisation) }
    let!(:motif3) { create(:motif, :for_secretariat, service: service, organisation: organisation) }
    let!(:motif4) { create(:motif, service: service, organisation: create(:organisation)) }
    let!(:motif5) { create(:motif, service: create(:service), organisation: organisation) }
    let(:plage_ouverture) { build(:plage_ouverture, agent: agent, organisation: organisation) }

    subject { Motif.available_motifs_for_organisation_and_agent(motif.organisation, agent) }

    describe "for secretaire" do
      let(:agent) { create(:agent, :secretaire, organisations: [organisation]) }
      it { is_expected.to contain_exactly(motif3) }
    end

    describe "for other service" do
      let(:agent) { create(:agent, service: service, organisations: [organisation]) }

      it { is_expected.to contain_exactly(motif, motif2, motif3) }
    end

    describe "for admin" do
      let(:agent) { create(:agent, :admin, organisations: [organisation]) }
      it { is_expected.to contain_exactly(motif, motif2, motif3, motif5) }
    end

    describe "for secretary admin" do
      let(:agent) { create(:agent, :secretaire, :admin, organisations: [organisation]) }
      it { is_expected.to contain_exactly(motif, motif2, motif3, motif5) }
    end
  end

  describe "#authorized_agents" do
    let(:org1) { create(:organisation) }
    let!(:service_pmi) { create(:service, name: "PMI") }
    let!(:service_secretariat) { create(:service, name: Service::SECRETARIAT) }
    let!(:agent_pmi1) { create(:agent, organisations: [org1], service: service_pmi) }
    let!(:agent_pmi2) { create(:agent, organisations: [org1], service: service_pmi) }
    let!(:agent_secretariat1) { create(:agent, organisations: [org1], service: service_secretariat) }
    let!(:motif) { create(:motif, service: service_pmi, organisation: org1) }

    subject { motif.authorized_agents.to_a }

    it { should match_array([agent_pmi1, agent_pmi2]) }

    context "motif is available for secretariat" do
      let!(:motif) { create(:motif, service: service_pmi, organisation: org1, for_secretariat: true) }
      it { should match_array([agent_pmi1, agent_pmi2, agent_secretariat1]) }
    end

    context "agent from same service but different orga" do
      let(:org2) { create(:organisation) }
      let!(:agent_pmi3) { create(:agent, organisations: [org2], service: service_pmi) }
      it { should_not include(agent_pmi3) }
    end
  end

  describe "secretariat?" do
    it "return true if motif for_secretariat" do
      motif = build(:motif, for_secretariat: true, organisation: organisation)
      expect(motif.secretariat?).to be true
    end

    it "return false if motif for_secretariat" do
      motif = build(:motif, for_secretariat: false, organisation: organisation)
      expect(motif.secretariat?).to be false
    end
  end

  describe "visible_and_notified?" do
    it "vrai quand visible_type == visible_and_notified" do
      motif = build(:motif, :visible_and_notified)
      expect(motif.visible_and_notified?).to eq(true)
    end

    it "faux quand visible_type == visible_and_not_notified" do
      motif = build(:motif, :visible_and_not_notified)
      expect(motif.visible_and_notified?).to eq(false)
    end

    it "faux quand visible_type == invisible" do
      motif = build(:motif, :invisible)
      expect(motif.visible_and_notified?).to eq(false)
    end
  end
end
