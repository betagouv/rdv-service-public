describe Service, type: :model do
  let(:service) { create(:service) }
  let!(:service2) { create(:service) }

  describe ".with_online_and_active_motifs_for_departement" do
    subject { Service.with_online_and_active_motifs_for_departement(motif.organisation.departement) }

    let!(:motif) { create(:motif, service: service, reservable_online: true) }
    let!(:plage_ouverture) { create(:plage_ouverture, motifs: [motif]) }

    it { is_expected.to contain_exactly(service) }

    context "without plage_ouverture" do
      let!(:motif2) { create(:motif, service: service, reservable_online: true) }

      it { is_expected.to contain_exactly(service) }
    end

    context "with an offline motif" do
      let!(:motif) { create(:motif, service: service, reservable_online: false) }

      it { is_expected.to eq([]) }
    end

    context "with an deleted motif" do
      let!(:motif) { create(:motif, service: service, reservable_online: true, deleted_at: Time.now) }

      it { is_expected.to eq([]) }
    end
  end
end
