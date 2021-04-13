describe Motif, type: :model do
  let(:motif_with_rdv) { create(:motif, :with_rdvs, organisation: organisation) }
  let(:secretariat) { create(:service, :secretariat) }
  let(:motif) { create(:motif, organisation: organisation) }
  let!(:organisation) { create(:organisation) }

  it "have a valid factory" do
    expect(build(:motif)).to be_valid
  end

  it "invalid without #RRGGBB format's color" do
    expect(build(:motif, color: "vert")).to be_invalid
    expect(build(:motif, color: "002233")).to be_invalid
    expect(build(:motif, color: "#002233")).to be_valid
  end

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
      expect(described_class.all).to eq [motif_with_rdv]
      expect(motif_with_rdv.reload.deleted_at).to eq @delation_time
    end
  end

  describe "#available_motifs_for_organisation_and_agent" do
    subject { described_class.available_motifs_for_organisation_and_agent(motif.organisation, agent) }

    let(:service) { create(:service) }
    let!(:motif) { create(:motif, service: service, organisation: organisation) }
    let!(:motif2) { create(:motif, service: service, organisation: organisation) }
    let!(:motif3) { create(:motif, :for_secretariat, service: service, organisation: organisation) }
    let!(:motif4) { create(:motif, service: service, organisation: create(:organisation)) }
    let!(:motif5) { create(:motif, service: create(:service), organisation: organisation) }
    let(:plage_ouverture) { build(:plage_ouverture, agent: agent, organisation: organisation) }

    describe "for secretaire" do
      let(:agent) { create(:agent, :secretaire, basic_role_in_organisations: [organisation]) }

      it { is_expected.to contain_exactly(motif3) }
    end

    describe "for other service" do
      let(:agent) { create(:agent, services: [service], basic_role_in_organisations: [organisation]) }

      it { is_expected.to contain_exactly(motif, motif2, motif3) }
    end

    describe "for admin" do
      let(:agent) { create(:agent, admin_role_in_organisations: [organisation]) }

      it { is_expected.to contain_exactly(motif, motif2, motif3, motif5) }
    end

    describe "for secretary admin" do
      let(:agent) { create(:agent, :secretaire, admin_role_in_organisations: [organisation]) }

      it { is_expected.to contain_exactly(motif, motif2, motif3, motif5) }
    end
  end

  describe "#authorized_agents" do
    subject { motif.authorized_agents.to_a }

    let(:org1) { create(:organisation) }
    let!(:service_pmi) { create(:service, name: "PMI") }
    let!(:service_secretariat) { create(:service, name: Service::SECRETARIAT) }
    let!(:agent_pmi1) { create(:agent, basic_role_in_organisations: [org1], services: [service_pmi]) }
    let!(:agent_pmi2) { create(:agent, basic_role_in_organisations: [org1], services: [service_pmi]) }
    let!(:agent_secretariat1) { create(:agent, basic_role_in_organisations: [org1], services: [service_secretariat]) }
    let!(:motif) { create(:motif, service: service_pmi, organisation: org1) }

    it { is_expected.to match_array([agent_pmi1, agent_pmi2]) }

    context "motif is available for secretariat" do
      let!(:motif) { create(:motif, service: service_pmi, organisation: org1, for_secretariat: true) }

      it { is_expected.to match_array([agent_pmi1, agent_pmi2, agent_secretariat1]) }
    end

    context "agent from same service but different orga" do
      let(:org2) { create(:organisation) }
      let!(:agent_pmi3) { create(:agent, basic_role_in_organisations: [org2], services: [service_pmi]) }

      it { is_expected.not_to include(agent_pmi3) }
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

  describe "search_by_name_with_location_type" do
    context "some matching motif name + type" do
      subject { described_class.search_by_name_with_location_type("Rappel PMI-phone") }

      let!(:motif) { create(:motif, name: "Rappel PMI", location_type: :phone) }

      it { is_expected.to include(motif) }
    end

    context "no matching motif name" do
      subject { described_class.search_by_name_with_location_type("Rappel PMI-phone") }

      let!(:motif) { create(:motif, name: "Rien a voir", location_type: :phone) }

      it { is_expected.to be_empty }
    end

    context "nil param" do
      subject { described_class.search_by_name_with_location_type(nil) }

      let!(:motif) { create(:motif, name: "Rappel PMI", location_type: :phone) }

      it { is_expected.to be_empty }
    end
  end
end
