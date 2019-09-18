class Creneau
  include ActiveModel::Model

  attr_accessor :starts_at, :duration_in_min, :lieu

  def self.for_motif_and_lieu_from_time_range(motif, lieu, time_range)
    plages_ouverture = PlageOuverture.where(lieu: lieu).where("first_day < ?", time_range.begin).joins(:motifs).where(motifs: { id: motifs_ids })
    []
  end
end
