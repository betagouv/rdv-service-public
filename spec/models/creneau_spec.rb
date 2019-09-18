describe Creneau, type: :model do
  let!(:motif) { create(:motif, name: "Vaccination") }
  let!(:lieu) { create(:lieu) }
  let!(:plage_ouverture) { create(:plage_ouverture, :daily, motifs: [motif], lieu: lieu) }
  let!(:lieu2) { create(:lieu) }
  let!(:plage_ouverture2) { create(:plage_ouverture, :daily, motifs: [motif], lieu: lieu2) }
  let!(:user) { create(:user) }
  let(:organisation) { plage_ouverture.organisation }

  describe ".for_motif_and_lieu_from_time_range" do
    let(:motif_name) { motif.name }
    let(:next_7_days_range) { Time.current..(7.days.from_now) }

    subject { Creneau.for_motif_and_lieu_from_time_range(motif_name, lieu, next_7_days_range) }

    before { freeze_time }
    after { travel_back }

    it { expect(subject).to eq([]) }
  end
end
