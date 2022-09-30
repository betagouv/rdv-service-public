# frozen_string_literal: true

describe OnlineBookingsHelper do
  describe "#motifs_checkbox_text" do
    context "when there is no motifs" do
      it { expect(motifs_checkbox_text([])).to match(/Ouvrir un motif à la réservation en ligne/) }
    end

    context "when there is one motif" do
      it { expect(motifs_checkbox_text(%w[motif])).to match(/Vous avez 1 motif ouvert à la réservation en ligne/) }
    end

    context "when there is multiple motifs" do
      it { expect(motifs_checkbox_text(%w[motif_a motif_b])).to match(/Vous avez 2 motifs ouverts à la réservation en ligne/) }
    end
  end

  describe "#plage_ouvertures_checkbox_text" do
    context "when there is no plages d'ouverture" do
      it { expect(plage_ouvertures_checkbox_text([])).to match(/Ajouter des plages d'ouverture pour les motifs ouverts à la réservation en ligne/) }
    end

    context "when there is one plage d'ouverture" do
      it { expect(plage_ouvertures_checkbox_text(%w[motif])).to match(/Vous avez 1 plage d'ouverture liée à des motifs réservables en ligne/) }
    end

    context "when there is multiple plages d'ouverture" do
      it { expect(plage_ouvertures_checkbox_text(%w[motif_a motif_b])).to match(/Vous avez 2 plages d'ouverture liées à des motifs réservables en ligne/) }
    end
  end
end
