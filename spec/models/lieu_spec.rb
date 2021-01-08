describe Lieu, type: :model do
  let!(:motif) { create(:motif, name: "Vaccination", reservable_online: reservable_online) }
  let!(:lieu) { create(:lieu) }
  let!(:plage_ouverture) { create(:plage_ouverture, :daily, motifs: [motif], lieu: lieu) }
  let!(:user) { create(:user) }
  let(:organisation) { plage_ouverture.organisation }

  describe ".for_motif_and_departement" do
    let(:motif_name) { motif.name }
    let(:service_id) { Service.first.id }
    let(:departement) { organisation.departement }
    let(:reservable_online) { true }

    subject { Lieu.for_motif_and_departement(motif_name, departement) }

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

    context "with a motif not reservable_online" do
      let(:reservable_online) { false }

      it { expect(subject).to eq([]) }
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

  describe ".for_motif" do
    subject { Lieu.for_motif(motif) }
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
    subject { Lieu.with_open_slots_for_motifs([motif]) }

    context "motif has current plage ouvertures" do
      let!(:motif) { create(:motif, name: "Vaccination") }
      let!(:plage_ouverture) { create(:plage_ouverture, :daily, motifs: [motif], lieu: lieu) }
      it { should include(lieu) }
    end

    context "motif has finished plage ouverture" do
      let!(:motif) { create(:motif, name: "Vaccination") }
      let!(:plage_ouverture) { create(:plage_ouverture, :daily, motifs: [motif], lieu: lieu, first_day: 2.days.ago, recurrence: nil) }
      it { should_not include(lieu) }
    end

    context "motif has no plage ouvertures" do
      let!(:motif) { create(:motif, name: "Vaccination") }
      let(:plage_ouverture) { nil }
      it { should_not include(lieu) }
    end
  end
end
