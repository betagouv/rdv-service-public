describe Creneau, type: :model do
  let!(:pro) { create(:pro, first_name: "Alain") }
  let!(:pro2) { create(:pro, first_name: "Robert") }
  let!(:motif) { create(:motif, name: "Vaccination") }
  let!(:plage_ouverture) { create(:plage_ouverture, :daily, motifs: [motif]) }
  let!(:user) { create(:user) }
  let(:organisation) { pro.organisation }

  describe ".for_motif_and_departement_from_time" do
    let(:motif_name) { motif.name }
    let(:departement) { organisation.departement }
    let(:now) { Time.current }

    subject { Creneau.for_motif_and_departement_from_time(motif_name, departement, now) }

    before { freeze_time }
    after { travel_back }

    it "should work" do
      expect(subject).to eq([])

    end
  end
end
