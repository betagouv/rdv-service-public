RSpec.describe Rdv::VisioConcern, type: :concern do
  describe "validation des URL custom" do
    subject { rdv.valid? }

    let(:rdv) { build(:rdv, visio_url_custom:) }

    context "nil" do
      let(:visio_url_custom) { nil }

      it { is_expected.to be true }
    end

    context "vide" do
      let(:visio_url_custom) { "" }

      it { is_expected.to be true }
    end

    context "valide" do
      let(:visio_url_custom) { "https://webinaire.numerique.gouv.fr/test-123" }

      it { is_expected.to be true }
    end

    context "mal formée" do
      let(:visio_url_custom) { "hptts://hackeverything" }

      specify do
        expect(rdv.valid?).to be false
        expect(rdv.errors[:visio_url_custom].first).to eq("n'est pas une URL valide")
      end
    end

    context "domaine non autorisé" do
      let(:visio_url_custom) { "https://outil-inconnu.fr/test-123" }

      specify do
        expect(rdv.valid?).to be false
        expect(rdv.errors[:visio_url_custom].first).to match(/doit provenir d’un des domaines suivants/)
      end
    end
  end
end
