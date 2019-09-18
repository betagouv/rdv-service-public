class Creneau
  include ActiveModel::Model

  attr_accessor :starts_at, :duration_in_min, :lieu

  def self.for_motif_and_departement_from_time(motif, departement, start_time)
    []
  end
end
