class Creneau
  include ActiveModel::Model

  attr_accessor :starts_at, :duration_in_min, :lieu_id, :motif

  def ends_at
    starts_at + duration_in_min.minutes
  end

  def lieu
    Lieu.find(lieu_id)
  end

  def available?(rdvs, absences)
    !overlaps_rdv_or_absence?(rdvs) &&
      !overlaps_rdv_or_absence?(absences) &&
      !too_late?
  end

  def too_late?
    (starts_at - motif.min_booking_delay) < Time.zone.now
  end

  def overlaps_rdv_or_absence?(rdvs_or_absences)
    rdvs_or_absences.select do |r_o_a|
      (starts_at < r_o_a.ends_at && r_o_a.ends_at < ends_at) ||
        (starts_at < r_o_a.starts_at && r_o_a.starts_at < ends_at) ||
        (r_o_a.starts_at <= starts_at && ends_at <= r_o_a.ends_at)
    end.any?
  end

  def self.for_motif_and_lieu_from_date_range(motif_name, lieu, inclusive_date_range)
    plages_ouverture = PlageOuverture.for_motif_and_lieu_from_date_range(motif_name, lieu, inclusive_date_range)

    plages_ouverture.flat_map do |po|
      rdvs = po.pro.rdvs.where(starts_at: inclusive_date_range)
      absences = po.pro.absences

      po.motifs.flat_map do |motif|
        creneaux_nb = po.time_shift_duration_in_min / motif.default_duration_in_min
        po.occurences_for(inclusive_date_range).flat_map do |occurence_time|
          (0...creneaux_nb).map do |n|
            creneau = Creneau.new(
              starts_at: (po.start_time + (n * motif.default_duration_in_min * 60)).on(occurence_time),
              duration_in_min: motif.default_duration_in_min,
              lieu_id: lieu.id,
              motif: motif
            )
            creneau.available?(rdvs, absences) ? creneau : nil
          end.compact
        end
      end
    end.uniq { |creneau| creneau.starts_at }.sort_by(&:starts_at)
  end
end
