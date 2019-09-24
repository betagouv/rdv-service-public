describe Lieu, type: :model do
  let!(:motif) { create(:motif, name: "Vaccination", online: online) }
  let!(:lieu) { create(:lieu) }
  let!(:plage_ouverture) { create(:plage_ouverture, :daily, motifs: [motif], lieu: lieu) }
  let!(:user) { create(:user) }
  let(:organisation) { plage_ouverture.organisation }

  describe ".for_motif_and_departement_in_date_range" do
    let(:motif_name) { motif.name }
    let(:departement) { organisation.departement }
    let(:date_range) { Time.current.to_date..(Time.current.to_date + 6.days) }
    let(:online) { true }

    subject { Lieu.for_motif_and_departement_in_date_range(motif_name, departement, date_range) }

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

      it { expect(subject).to contain_exactly(lieu) }
    end

    context "with a motif not online" do
      let(:online) { false }

      it { expect(subject).to eq([]) }
    end

    # context "with a plage_ouverture ended (To be implemented)" do
    #   let!(:lieu2) { create(:lieu) }
    #   let!(:plage_ouverture2) { create(:plage_ouverture, :daily, motifs: [motif], lieu: lieu2, first_day: 2.days.from_now) }
    #
    #   it { expect(subject).to contain_exactly(lieu) }
    # end
  end
end
