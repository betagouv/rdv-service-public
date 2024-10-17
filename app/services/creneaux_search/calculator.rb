module CreneauxSearch::Calculator
  class << self
    # méthode publique
    def available_slots(motif, lieu, date_range, agents = [])
      datetime_range = CreneauxSearch::Range.ensure_date_range_with_time(date_range)
      plage_ouvertures = plage_ouvertures_for(motif, lieu, datetime_range, agents)
      free_times_po = free_times_from(plage_ouvertures, datetime_range) # dépendances implicite à Rdv, Absence et OffDays
      slots_for(free_times_po, motif).select do |slot|
        slot.starts_at >= datetime_range.begin
      end
    end

    def plage_ouvertures_for(motif, lieu, datetime_range, agents)
      scope = PlageOuverture.not_expired
        .merge(motif.plage_ouvertures)
        .in_range(datetime_range)
        .includes(:agent)
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

      ranges.map do |range|
        [range, BusyTimePreloader.preload_busy_times_for(range, plage_ouverture)]
      end.flat_map do |range, busy_times_preloader|
        busy_times = busy_times_preloader.busy_times
        split_range_recursively(range, busy_times)
      end
    end

    def ranges_for(plage_ouverture, datetime_range)
      occurrences = plage_ouverture.occurrences_for(datetime_range)

      occurrences.map do |occurrence|
        next if occurrence.ends_at < Time.zone.now

        occurrence.starts_at..occurrence.ends_at
      end.compact
    end

    # On enlève les intervalles occupés d'un morceau de plage d'ouverture
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

      range if (busy_time.ends_at < range.begin) || (busy_time.starts_at > range.end) # Dans ce dernier cas il n'y a pas d'overlap du tout entre le range et le busy_time
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

  class BusyTimePreloader
    def initialize(range, plage_ouverture)
      @range = range
      @plage_ouverture = plage_ouverture
    end

    attr_reader :range, :plage_ouverture

    def self.preload_busy_times_for(range, plage_ouverture)
      new(range, plage_ouverture).tap(&:preload)
    end

    def preload
      # c'est là que l'on execute le SQL
      # TODO : Peut-être cacher la récupération de l'ensemble des RDV et absences concernées (pour n'avoir que deux requêtes) puis faire des selections dessus pour le filtre sur le range
      #        Le problème potentiel de cette approche est qu'il serait difficile d'éviter de charger des rdv et absences qui sont en dehors des ocurrences des plages d'ouverture

      # On lance le chargement des absences en asynchrone pendant qu'on calcule les autres busy times
      @absences = plage_ouverture.agent.absences.not_expired.in_range(range).load_async
      @rdvs = plage_ouverture.agent.rdvs.not_cancelled.where("tsrange(starts_at, ends_at, '[)') && tsrange(?, ?)", range.begin, range.end).load_async
    end

    def busy_times
      busy_times = busy_times_from_off_days

      busy_times += busy_times_from_absences

      busy_times += @rdvs.map do |rdv|
        BusyTime.new(rdv.starts_at, rdv.ends_at)
      end

      # Le tri est nécessaire, surtout pour les surcharges.
      busy_times.sort_by(&:starts_at)
    end

    private

    def busy_times_from_absences
      busy_times = []
      @absences.each do |absence|
        absence.occurrences_for(range).each do |absence_occurrence|
          next if absence_out_of_range?(absence_occurrence)

          busy_times << BusyTime.new(absence_occurrence.starts_at, absence_occurrence.ends_at)
        end
      end
      busy_times
    end

    def absence_out_of_range?(absence)
      absence.ends_at < range.begin || range.end < absence.starts_at
    end

    def busy_times_from_off_days
      OffDays.all_in_date_range(range).map do |off_day|
        BusyTime.new(off_day.beginning_of_day, off_day.end_of_day)
      end
    end
  end

  class BusyTime
    attr_reader :starts_at, :ends_at

    def initialize(starts_at, ends_at)
      @starts_at = starts_at
      @ends_at = ends_at
    end

    def range
      (starts_at..ends_at)
    end
  end
end
