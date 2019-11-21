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

  describe '.names_grouped_by_service_for_departement' do
    let(:service) { create(:service) }
    let!(:service2) { create(:service) }

    subject { Motif.names_grouped_by_service_for_departement(organisation.departement) }

    describe "when motif is online" do
      let!(:motif) { create(:motif, service: service, online: true, deleted_at: deleted_at) }
      let(:deleted_at) { nil }

      it { is_expected.to eq([]) }

      describe "with a plage_ouverture" do
        let!(:plage_ouverture) { create(:plage_ouverture, motifs: [motif]) }

        it { expect(subject.size).to eq(1) }
        it { expect(subject.first.first).to eq(service.name) }
        it { expect(subject.first.second).to contain_exactly(motif.name) }

        describe "but motif is deleted" do
          let(:deleted_at) { Time.zone.now }

          it { is_expected.to eq([]) }
        end

        describe "with a second motif" do
          let!(:motif2) { create(:motif, service: service, online: true, deleted_at: deleted_at2) }
          let!(:plage_ouverture2) { create(:plage_ouverture, motifs: [motif2]) }
          let(:deleted_at2) { nil }

          it { expect(subject.size).to eq(1) }
          it { expect(subject.first.first).to eq(service.name) }
          it { expect(subject.first.second).to contain_exactly(motif.name, motif2.name) }

          describe "wich is deleted" do
            let(:deleted_at2) { Time.zone.now }

            it { expect(subject.first.second).to contain_exactly(motif.name) }
          end

          describe "which has same name" do
            let(:organisation2) { create(:organisation) }
            let!(:motif2) { create(:motif, service: service, online: true, deleted_at: deleted_at2, name: motif.name, organisation: organisation2) }
            let!(:plage_ouverture2) { create(:plage_ouverture, motifs: [motif2], organisation: organisation2) }

            it { expect(subject.first.second).to contain_exactly(motif.name) }
          end
        end
      end
    end

    describe "when motif is not online" do
      let!(:motif_offline) { create(:motif, service: service, online: false) }
      let!(:motif_online) { create(:motif, service: service, online: true) }

      it { is_expected.to eq([]) }

      describe "with a plage_ouverture" do
        let!(:plage_ouverture) { create(:plage_ouverture, motifs: [motif_offline, motif_online]) }

        it { expect(subject.size).to eq(1) }
        it { expect(subject.first.first).to eq(service.name) }
        it { expect(subject.first.second).to contain_exactly(motif_online.name) }
      end
    end
  end

  describe "#available_motifs_for_organisation_and_agent" do
    let!(:motif) { create(:motif) }
    let!(:motif2) { create(:motif) }
    let!(:motif3) { create(:motif, :by_phone) }
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
