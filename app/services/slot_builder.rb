# frozen_string_literal: true

module SlotBuilder
  class << self
    # méthode publique
    def available_slots(motif, lieu, date_range, off_days, agents = [])
      datetime_range = ensure_date_range_with_time(date_range)
      plage_ouvertures = plage_ouvertures_for(motif, lieu, datetime_range, agents)
      free_times_po = free_times_from(plage_ouvertures, datetime_range, off_days) # dépendance sur RDV et Absence
      slots_for(free_times_po, motif)
    end

    def ensure_date_range_with_time(date_range)
      time_begin = date_range.begin.is_a?(Time) ? date_range.begin : date_range.begin.beginning_of_day
      time_begin = Time.zone.now if time_begin < Time.zone.now
      time_end = date_range.end.is_a?(Time) ? date_range.end : date_range.end.end_of_day

      time_begin..time_end
    end

    def plage_ouvertures_for(motif, lieu, datetime_range, agents)
      PlageOuverture.not_expired
        .merge(lieu.plage_ouvertures)
        .merge(motif.plage_ouvertures)
        .in_range(datetime_range)
        .includes(%i[organisation agent])
        .where(({ agent: agents } if agents&.any?))
    end

    def free_times_from(plage_ouvertures, datetime_range, off_days)
      free_times = {}
      plage_ouvertures.each do |plage_ouverture|
        free_times[plage_ouverture] = calculate_free_times(plage_ouverture, datetime_range, off_days)
      end
      free_times.select { |_, v| v&.any? }
    end

    def calculate_free_times(plage_ouverture, datetime_range, off_days)
      ranges = ranges_for(plage_ouverture, datetime_range)
      return [] if ranges.empty?

      ranges.flat_map do |range|
        busy_times = BusyTime.busy_times_for(range, plage_ouverture, off_days)
        split_range_recursively(range, busy_times)
      end
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
      return [range.begin..busy_time.starts_at] if range.begin < busy_time.starts_at && range.cover?(busy_time.range)

      []
    end

    def remaining_range(range, busy_time)
      return busy_time.ends_at..range.end if range.cover?(busy_time.range)
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
      when Date
        @starts_at = object.beginning_of_day
        @ends_at = object.end_of_day
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

    class << self
      def busy_times_for(range, plage_ouverture, off_days = [])
        # c'est là que l'on execute le SQL
        # TODO : Peut-être cacher la récupération de l'ensemble des RDV et absences concernées (pour n'avoir que deux requêtes) puis faire des selections dessus pour le filtre sur le range

        busy_times = busy_times_from_rdvs(range, plage_ouverture)
        busy_times += busy_times_from_absences(range, plage_ouverture)
        busy_times += busy_times_from_off_days(off_days.select { |off_day| range.cover?(off_day) })
        # Le tri est nécessaire, surtout pour les surcharges.
        busy_times.sort_by(&:starts_at)
      end

      def busy_times_from_rdvs(range, plage_ouverture)
        rdv_starts_in_range = plage_ouverture.agent.rdvs.not_cancelled.where(starts_at: range)
        rdv_ends_in_range = plage_ouverture.agent.rdvs.not_cancelled.where(ends_at: range)
        rdv_over_range = plage_ouverture.agent.rdvs.not_cancelled.where("starts_at <= ?", range.begin).where("ends_at >= ?", range.end)
        rdv_starts_in_range.or(rdv_ends_in_range).or(rdv_over_range).map do |rdv|
          BusyTime.new(rdv)
        end
      end

      def busy_times_from_absences(range, plage_ouverture)
        absences = plage_ouverture.agent.absences
          .not_expired
          .where(organisation: plage_ouverture.organisation)
          .in_range(range)
        busy_times = []
        absences.each do |absence|
          if absence.recurrence
            absence.occurrences_for(range).each do |absence_occurrence|
              next if absence_out_of_range?(absence_occurrence, range)

              busy_times << BusyTime.new(absence_occurrence)
            end
          else
            next if absence_out_of_range?(absence, range)

            busy_times << BusyTime.new(absence)
          end
        end
        busy_times
      end

      def absence_out_of_range?(absence, range)
        if absence.is_a?(Recurrence::Occurrence)
          start_date_time = absence.starts_at
          end_date_time = absence.ends_at
        else
          start_date_time = absence.start_time.on(absence.first_day)
          end_date_time = absence.end_time.on(absence.end_day)
        end
        end_date_time < range.begin || range.end < start_date_time
      end

      def busy_times_from_off_days(off_days)
        busy_times = []
        off_days.each do |off_day|
          busy_times << BusyTime.new(off_day)
        end
        busy_times
      end
    end
  end
end
