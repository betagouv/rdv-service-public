# frozen_string_literal: true

# Permet de passer de 1 motif à 3 motifs pour les mairies
def duplicate_motifs(source_motif)
  motif_cni = source_motif.dup
  motif_cni.update!(
    name: "Carte d'identité",
    motif_category: MotifCategory.find_by(name: "Carte d'identité disponible sur le site de l'ANTS")
  )

  motif_passport = source_motif.dup
  motif_passport.update!(
    name: "Passeport",
    motif_category: MotifCategory.find_by(name: "Passeport disponible sur le site de l'ANTS")
  )

  motif_cni_passport = source_motif.dup
  motif_cni_passport.update!(
    name: "Carte d'identité et passeport",
    motif_category: MotifCategory.find_by(name: "Carte d'identité et passeport disponible sur le site de l'ANTS")
  )

  source_motif.plage_ouvertures.each do |po|
    po.motifs << [motif_cni, motif_passport, motif_cni_passport]
    po.save!
  end
end
