describe Rdv, type: :model do
  let!(:organisation) { Organisation.last || create(:organisation) }
  let(:motif) { create(:motif) }
  let(:secretariat) { create(:service, :secretariat) }
  let(:motif_with_rdv) { create(:motif, :with_rdvs) }

  describe '.create when associated with secretariat' do
    let(:motif) { build(:motif, service: secretariat) }
    it {
      expect(motif.valid?).to be false
    }
  end

  describe '#soft_delete' do
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
    let!(:motif) { create(:motif) }
    let!(:motif2) { create(:motif) }
    let!(:motif3) { create(:motif, :for_secretariat) }
    let!(:motif4) { create(:motif, organisation: create(:organisation)) }
    let(:plage_ouverture) { build(:plage_ouverture, agent: agent) }

    subject { Motif.available_motifs_for_organisation_and_agent(motif.organisation, agent) }

    describe "for secretaire" do
      let(:agent) { create(:agent, :secretaire) }
      it { is_expected.to contain_exactly(motif3) }
    end

    describe "for other service" do
      let(:agent) { create(:agent, service: motif.service) }

      it { is_expected.to contain_exactly(motif, motif2, motif3) }
    end
  end
end
