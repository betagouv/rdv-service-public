describe Lieu, type: :model do
  let!(:territory) { create(:territory, departement_number: "62") }
  let!(:organisation) { create(:organisation, territory: territory) }
  let!(:lieu) { create(:lieu) }
  let!(:user) { create(:user) }

  context "with motif" do
    let!(:motif) { create(:motif, name: "Vaccination", reservable_online: reservable_online, organisation: organisation) }
    let!(:plage_ouverture) { create(:plage_ouverture, :daily, motifs: [motif], lieu: lieu, organisation: organisation) }

    describe ".for_motif" do
      subject { described_class.for_motif(motif) }

      let(:reservable_online) { false }

      before { freeze_time }

      after { travel_back }

      it { expect(subject).to contain_exactly(lieu) }

      context "with an other plage_ouverture" do
        let!(:lieu2) { create(:lieu) }
        let!(:plage_ouverture2) { create(:plage_ouverture, :daily, motifs: [motif], lieu: lieu2) }

        it { expect(subject).to contain_exactly(lieu, lieu2) }
      end

      context "with a plage_ouverture not yet started" do
        let!(:lieu2) { create(:lieu) }
        let!(:plage_ouverture2) { create(:plage_ouverture, :daily, motifs: [motif], lieu: lieu2, first_day: 8.days.from_now) }

        it { expect(subject).to contain_exactly(lieu, lieu2) }
      end

      context "with a plage_ouverture with no recurrence and closed" do
        let!(:lieu2) { create(:lieu) }
        let!(:plage_ouverture2) { create(:plage_ouverture, motifs: [motif], lieu: lieu2, first_day: Date.parse("2020-07-30")) }

        it { expect(subject).to contain_exactly(lieu) }
      end

      context "with a motif not active" do
        before { motif.update(deleted_at: Time.zone.now) }

        it { expect(subject).to eq([]) }
      end
    end

    describe ".distance" do
      let!(:lieu_lille) { create(:lieu, latitude: 50.63, longitude: 3.053) }
      let(:paris_loc) { { latitude: 48.83, longitude: 2.37 } }
      let(:reservable_online) { true }

      it { expect(lieu_lille.distance(paris_loc[:latitude], paris_loc[:longitude])).to be_a_kind_of(Float) }
      it { expect(lieu_lille.distance(paris_loc[:latitude], paris_loc[:longitude])).to be_within(10_000).of(204_000) }
    end

    describe "#with_open_slots_for_motifs" do
      subject { described_class.with_open_slots_for_motifs([motif]) }

      context "motif has current plage ouvertures" do
        let!(:motif) { create(:motif, name: "Vaccination") }
        let!(:plage_ouverture) { create(:plage_ouverture, :daily, motifs: [motif], lieu: lieu) }

        it { is_expected.to include(lieu) }
      end

      context "motif has finished plage ouverture" do
        let!(:motif) { create(:motif, name: "Vaccination") }
        let!(:plage_ouverture) { create(:plage_ouverture, :daily, motifs: [motif], lieu: lieu, first_day: 2.days.ago, recurrence: nil) }

        it { is_expected.not_to include(lieu) }
      end

      context "motif has no plage ouvertures" do
        let!(:motif) { create(:motif, name: "Vaccination") }
        let(:plage_ouverture) { nil }

        it { is_expected.not_to include(lieu) }
      end
    end
  end

  describe "#destroy" do
    it "dont destroy lieu when it have rdvs" do
      lieu = create(:lieu, organisation: organisation, rdvs: [create(:rdv)])
      expect(lieu.destroy).to be(false)
    end

    it "dont destroy lieu when it have plage_ouvertures" do
      lieu = create(:lieu, organisation: organisation, plage_ouvertures: [create(:plage_ouverture)])
      expect(lieu.destroy).to be(false)
    end

    it "destroy lieu without rdvs or plage d'ouverture" do
      lieu = create(:lieu, organisation: organisation, rdvs: [], plage_ouvertures: [])
      expect(lieu.destroy).to eq(lieu)
    end
  end
end
