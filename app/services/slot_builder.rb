# frozen_string_literal: true

module SlotBuilder
  class << self
    # méthode publique
    def available_slots(motif, lieu, date_range, agents = [])
      datetime_range = Lapin::Range.ensure_date_range_with_time(date_range)
      plage_ouvertures = plage_ouvertures_for(motif, lieu, datetime_range, agents)
      free_times_po = free_times_from(plage_ouvertures, datetime_range) # dépendances implicite à Rdv, Absence et OffDays
      slots_for(free_times_po, motif)
    end

    def plage_ouvertures_for(motif, lieu, datetime_range, agents)
      scope = PlageOuverture.not_expired
        .merge(motif.plage_ouvertures)
        .in_range(datetime_range)
        .includes(%i[organisation agent])
      scope = scope.where(agent: agents) if agents&.any?
      scope = scope.where(lieu: lieu) if lieu.present?
      scope
    end

    def free_times_from(plage_ouvertures, datetime_range)
      free_times = {}
      plage_ouvertures.each do |plage_ouverture|
        free_times[plage_ouverture] = calculate_free_times(plage_ouverture, datetime_range)
      end
      free_times.select { |_, v| v&.any? }
    end

    def calculate_free_times(plage_ouverture, datetime_range)
      ranges = ranges_for(plage_ouverture, datetime_range)
      return [] if ranges.empty?

      ranges.flat_map do |range|
        busy_times = BusyTime.busy_times_for(range, plage_ouverture)
        split_range_recursively(range, busy_times)
      end
    end

    def ranges_for(plage_ouverture, datetime_range)
      occurrences = plage_ouverture.occurrences_for(datetime_range, only_future: true)

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
      possible_slot_start = earliest_possible_slot_start(free_time)
      last_possible_slot_start = free_time.end - motif.default_duration_in_min.minutes

      slots = []

      while possible_slot_start <= last_possible_slot_start
        slots << Creneau.new(
          starts_at: possible_slot_start,
          motif: motif,
          lieu_id: plage_ouverture.lieu_id,
          agent: plage_ouverture.agent
        )
        possible_slot_start += motif.default_duration_in_min.minutes
      end
      slots
    end

    def earliest_possible_slot_start(free_time)
      earliest_possible_start = Time.zone.now

      possible_slot_start = free_time.begin

      if free_time.begin < earliest_possible_start
        step_length = 5.minutes

        possible_slot_start += step_length * ((earliest_possible_start - free_time.begin) / step_length).ceil
      end

      possible_slot_start
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
      def busy_times_for(range, plage_ouverture)
        # c'est là que l'on execute le SQL
        # TODO : Peut-être cacher la récupération de l'ensemble des RDV et absences concernées (pour n'avoir que deux requêtes) puis faire des selections dessus pour le filtre sur le range

        busy_times = busy_times_from_rdvs(range, plage_ouverture)
        busy_times += busy_times_from_absences(range, plage_ouverture)
        busy_times += busy_times_from_off_days(range)
        # Le tri est nécessaire, surtout pour les surcharges.
        busy_times.sort_by(&:starts_at)
      end

      def busy_times_from_rdvs(range, plage_ouverture)
        plage_ouverture.agent.rdvs.not_cancelled.where("tsrange(starts_at, ends_at, '[)') && tsrange(?, ?)", range.begin, range.end).map do |rdv|
          BusyTime.new(rdv)
        end
      end

      def busy_times_from_absences(range, plage_ouverture)
        absences = plage_ouverture.agent.absences
          .not_expired
          .in_range(range)
        busy_times = []
        absences.each do |absence|
          if absence.recurrence
            absence.occurrences_for(range, only_future: true).each do |absence_occurrence|
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

      def busy_times_from_off_days(date_range)
        OffDays.all_in_date_range(date_range).map { |off_day| BusyTime.new(off_day) }
      end
    end
  end
end
