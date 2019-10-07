describe Service, type: :model do
  let(:service) { create(:service) }
  let!(:service2) { create(:service) }

  describe '.with_online_motif_in_departement' do
    subject { Service.with_online_motif_in_departement(service.organisation.departement) }

    describe "when motif is online" do
      let!(:motif) { create(:motif, service: service, online: true, deleted_at: deleted_at) }
      let(:deleted_at) { nil }

      it { is_expected.to eq([]) }

      describe "with a plage_ouverture" do
        let!(:plage_ouverture) { create(:plage_ouverture, motifs: [motif]) }

        it { is_expected.to contain_exactly(service) }

        describe "but motif is deleted" do
          let(:deleted_at) { Time.zone.now }

          it { is_expected.to eq([]) }
        end

        describe "with a second motif" do
          let!(:motif2) { create(:motif, service: service, online: true, deleted_at: deleted_at2) }
          let(:deleted_at2) { nil }

          it { is_expected.to contain_exactly(service) }
          it { expect(subject.first.motifs).to contain_exactly(motif, motif2) }

          describe "wich is deleted" do
            let(:deleted_at2) { Time.zone.now }

            it { expect(subject.first.motifs).to contain_exactly(motif) }
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

        it { expect(subject.first.motifs).to contain_exactly(motif_online) }
      end
    end
  end
end
