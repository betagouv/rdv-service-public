describe Lieu, type: :model do
  let!(:motif) { create(:motif, name: "Vaccination") }
  let!(:lieu) { create(:lieu) }
  let!(:plage_ouverture) { create(:plage_ouverture, :daily, motifs: [motif], lieu: lieu) }
  let!(:user) { create(:user) }
  let(:organisation) { plage_ouverture.organisation }

  describe ".for_motif_and_departement_from_time" do
    let(:motif_name) { motif.name }
    let(:departement) { organisation.departement }
    let(:now) { Time.current }

    subject { Lieu.for_motif_and_departement_from_time(motif_name, departement, now) }

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
      let!(:plage_ouverture2) { create(:plage_ouverture, :daily, motifs: [motif], lieu: lieu2, first_day: 2.days.from_now) }

      it { expect(subject).to contain_exactly(lieu) }
    end

    # context "with a plage_ouverture ended (To be implemented)" do
    #   let!(:lieu2) { create(:lieu) }
    #   let!(:plage_ouverture2) { create(:plage_ouverture, :daily, motifs: [motif], lieu: lieu2, first_day: 2.days.from_now) }
    #
    #   it { expect(subject).to contain_exactly(lieu) }
    # end
  end
end
