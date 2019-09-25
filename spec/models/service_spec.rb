describe Service, type: :model do
  let(:service) { create(:service) }
  let!(:service2) { create(:service) }

  describe '.with_online_motif_in_departement' do
    subject { Service.with_online_motif_in_departement(service.organisation.departement) }

    describe "when motif is online" do
      let!(:motif) { create(:motif, service: service, online: true) }

      it { is_expected.to eq([]) }

      describe "with a plage_ouverture" do
        let!(:plage_ouverture) { create(:plage_ouverture, motifs: [motif]) }

        it { is_expected.to contain_exactly(service) }
      end
    end

    describe "when motif is not online" do
      let!(:motif) { create(:motif, service: service, online: false) }

      it { is_expected.to eq([]) }

      describe "with a plage_ouverture" do
        let!(:plage_ouverture) { create(:plage_ouverture, motifs: [motif]) }

        it { is_expected.to eq([]) }
      end
    end
  end
end
