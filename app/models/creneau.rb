class Creneau
  include ActiveModel::Model

  attr_accessor :starts_at, :duration_in_min, :lieu_id, :motif_id, :plage_ouverture_id

  def motif
    Motif.find(motif_id)
  end

  def lieu
    Lieu.find(lieu_id)
  end

  def plage_ouverture
    PlageOuverture.find(plage_ouverture_id)
  end

  def self.for_motif_and_lieu_from_date_range(motif_name, lieu, inclusive_date_range)
    plages_ouverture = PlageOuverture.for_motif_and_lieu_from_date_range(motif_name, lieu, inclusive_date_range)

    plages_ouverture.flat_map do |po|
      po.motifs.flat_map do |motif|
        creneaux_nb = po.time_shift_duration_in_min / motif.default_duration_in_min
        po.occurences_for(inclusive_date_range).flat_map do |occurence_time|
          (0...creneaux_nb).map do |n|
            Creneau.new(
              starts_at: (po.start_time + (n * motif.default_duration_in_min * 60)).on(occurence_time),
              duration_in_min: 30,
              lieu_id: lieu.id,
              motif_id: motif.id,
              plage_ouverture_id: po.id,
            )
          end
        end
      end
    end
  end
end
