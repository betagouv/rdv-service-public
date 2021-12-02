# frozen_string_literal: true

module SlotBuilder
  # À faire avant, au moment de jouer avec le motifs
  # @for_agents ? motifs : motifs.reservable_online
  # Ce filtre est lié à la recherche de plage d'ouverture à partir d'un nom de motif... Est-ce vraiment nécessaire dans notre cas ?
  #
  # @for_agents sert aussi pour « limiter » l'afficahge des créneaux. Je pense que c'est à faire sur la vue.
  # uniq_by = @for_agents ? ->(c) { [c.starts_at, c.agent_id] } : ->(c) { c.starts_at }
  #  creneaux.uniq(&uniq_by).sort_by(&:starts_at)

  class << self
    # méthode publique
    def available_slots(motif, lieu, date_range, off_days, agent_ids = [])
      datetime_range = date_range.begin.beginning_of_day..date_range.end.end_of_day
      datetime_range = Time.zone.now..datetime_range.end.end_of_day if datetime_range.begin < Time.zone.now
      plage_ouvertures = plage_ouvertures_for(motif, lieu, datetime_range, agent_ids)
      free_times_po = free_times_from(plage_ouvertures, datetime_range, off_days) # dépendance sur RDV et Absence
      slots_for(free_times_po, motif)
    end

    def plage_ouvertures_for(motif, lieu, datetime_range, agent_ids)
      lieu.plage_ouvertures.merge(motif.plage_ouvertures).not_expired.in_range(datetime_range)
        .where(({ agent_id: agent_ids } if agent_ids&.any?))
    end

    def free_times_from(plage_ouvertures, datetime_range, off_days)
      free_times = {}
      plage_ouvertures.each do |plage_ouverture|
        free_times[plage_ouverture] = calculate_free_times(plage_ouverture, datetime_range, off_days)
      end
      free_times.select { |_, v| v&.any? }
    end

    def calculate_free_times(plage_ouverture, datetime_range, _off_days)
      ranges = ranges_for(plage_ouverture, datetime_range)
      return [] if ranges.empty?

      ranges.flat_map { |range| split_range_recursively(range, BusyTime.busy_times_for(range, plage_ouverture)) }
    end

    def ranges_for(plage_ouverture, datetime_range)
      occurrences = plage_ouverture.occurrences_for(datetime_range)

      occurrences.map do |occurrence|
        next if occurrence.ends_at < Time.zone.now

        (plage_ouverture.start_time.on(occurrence.starts_at)..plage_ouverture.end_time.on(occurrence.ends_at))
      end.compact
    end

    def split_range_recursively(range, busy_times)
      return [] if range.nil?
      return [range] if busy_times.empty?

      busy_time = busy_times.first

      first_range(range, busy_time) \
        + split_range_recursively(remaining_range(range, busy_time), busy_times - [busy_time])
    end

    def first_range(range, busy_time)
      return [range.begin..busy_time.starts_at] if range.begin < busy_time.starts_at && range.include?(busy_time.range)

      []
    end

    def remaining_range(range, busy_time)
      return busy_time.ends_at..range.end if range.include?(busy_time.range)
      return range.begin..busy_time.starts_at if range.cover?(busy_time.starts_at)
      return busy_time.ends_at..range.end if range.cover?(busy_time.ends_at)
    end

    def slots_for(plage_ouverture_free_times, motif)
      slots = []
      plage_ouverture_free_times.each do |plage_ouverture, free_times|
        free_times.each do |free_time|
          slots += calculate_slots(free_time, motif, plage_ouverture)
        end
      end
      slots
    end

    def calculate_slots(free_time, motif, plage_ouverture)
      slots = []
      possible_slot_time = free_time.begin..(free_time.begin + motif.default_duration_in_min.minutes)
      while possible_slot_time.end <= free_time.end
        slots << Creneau.new(
          starts_at: possible_slot_time.begin,
          motif: motif,
          lieu_id: plage_ouverture.lieu_id,
          agent: plage_ouverture.agent
        )
        possible_slot_time = possible_slot_time.end..(possible_slot_time.end + motif.default_duration_in_min.minutes)
      end
      slots
    end
  end

  class BusyTime
    attr_reader :starts_at, :ends_at

    def initialize(object)
      case object
      when Rdv, Recurrence::Occurrence
        @starts_at = object.starts_at
        @ends_at = object.ends_at
      when Absence
        @starts_at = object.start_time.on(object.first_day)
        @ends_at = object.end_time.on(object.end_day.presence || object.first_day)
      else
        raise ArgumentError, "busytime can't be build with a #{object.class}"
      end
    end

    def range
      (starts_at..ends_at)
    end

    def self.busy_times_for(range, plage_ouverture)
      # c'est là que l'on execute le SQL
      # TODO : Peut-être cacher la récupération de l'ensemble des RDV et absences concernées (pour n'avoir que deux requêtes) puis faire des selections dessus pour le filtre sur le range

      busy_times = busy_times_from_rdvs(range, plage_ouverture)
      busy_times += busy_times_from_absences(range, plage_ouverture)

      # Le tri est nécessaire, surtout pour les surcharges.
      busy_times.sort_by(&:starts_at)
    end

    def self.busy_times_from_rdvs(range, plage_ouverture)
      plage_ouverture_starts_in_range = plage_ouverture.agent.rdvs.not_cancelled.where(starts_at: range)
      plage_ouverture_ends_in_range = plage_ouverture.agent.rdvs.not_cancelled.where(ends_at: range)
      plage_ouverture_starts_in_range.or(plage_ouverture_ends_in_range).map do |rdv|
        BusyTime.new(rdv)
      end
    end

    def self.busy_times_from_absences(range, plage_ouverture)
      absences = plage_ouverture.agent.absences.where(organisation: plage_ouverture.organisation).in_range(range)
      busy_times = []
      absences.each do |absence|
        if absence.recurrence
          absence.occurrences_for(range).each do |absence_occurrence|
            busy_times << BusyTime.new(absence_occurrence)
          end
        else
          busy_times << BusyTime.new(absence)
        end
      end
      busy_times
    end
  end
end
