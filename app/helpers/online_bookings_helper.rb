# frozen_string_literal: true

module OnlineBookingsHelper
  def motifs_checkbox_text(motifs)
    if motifs.any?
      "Vous avez #{motifs.count} #{'motif'.pluralize(motifs.count)} #{'ouvert'.pluralize(motifs.count)} à la réservation en ligne"
    else
      "Ouvrir un motif à la réservation en ligne"
    end
  end

  def plage_ouvertures_checkbox_text(plage_ouvertures)
    if plage_ouvertures.any?
      "Vous avez #{plage_ouvertures.count} #{'plage'.pluralize(plage_ouvertures.count)} d'ouverture #{'liée'.pluralize(plage_ouvertures.count)} à des motifs réservables en ligne"
    else
      "Ajouter des plages d'ouverture pour les motifs ouverts à la réservation en ligne"
    end
  end
end
