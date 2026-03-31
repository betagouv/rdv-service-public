module CreneauxSearch::OldCalculator
  class << self
    # méthode publique
    def available_slots(motif:, lieu:, date_range:, agents: [], duration_in_min: nil)
      datetime_range = CreneauxSearch::Range.ensure_date_range_with_time(date_range)
      plage_ouvertures = plage_ouvertures_for(motif, lieu, datetime_range, agents)
      import_absences_from_caldav(plage_ouvertures.map(&:agent).uniq)

      # Cette méthode découpe les plages d'ouverture en fonction des absences, rdvs, et jours fériés
      free_times_po = free_times_from(
        plage_ouvertures,
        datetime_range,
        work_on_off_days: motif.organisation.territory.work_on_sunday? # La colonne `work_on_sunday` indique aussi que les agents travaillent les jours fériés
      )

      slots_for(free_times_po, motif, duration_in_min:).select do |slot|
        slot.starts_at >= datetime_range.begin
      end
    end

    def plage_ouvertures_for(motif, lieu, datetime_range, agents)
      scope = PlageOuverture.not_expired
        .merge(motif.plage_ouvertures)
        .in_range(datetime_range)
        .includes(:agent)
        .where(agent: Agent.excluding_pending_invitation)

      scope = scope.where(agent: agents) if agents&.any?
      scope = scope.where(lieu: lieu) if lieu.present?
      scope
    end

    def free_times_from(plage_ouvertures, datetime_range, work_on_off_days:)
      free_times = {}
      plage_ouvertures.each do |plage_ouverture|
        free_times[plage_ouverture] = calculate_free_times(plage_ouverture, datetime_range, work_on_off_days:)
      end
      free_times.select { |_, v| v&.any? }
    end

    def calculate_free_times(plage_ouverture, datetime_range, work_on_off_days:)
      ranges = ranges_for(plage_ouverture, datetime_range)
      return [] if ranges.empty?

      ranges.map do |range|
        [range, BusyTimePreloader.start_loading_busy_times_for(range, plage_ouverture.agent, work_on_off_days:)]
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

    def slots_for(plage_ouverture_free_times, motif, duration_in_min: nil)
      slots = []
      plage_ouverture_free_times.each do |plage_ouverture, free_times|
        free_times.each do |free_time|
          slots += calculate_slots(free_time, motif, plage_ouverture, duration_in_min:)
        end
      end
      slots
    end

    def calculate_slots(free_time, motif, plage_ouverture, duration_in_min: nil)
      possible_slot_start = earliest_possible_slot_start(free_time)
      duration_in_min ||= motif.default_duration_in_min
      last_possible_slot_start = free_time.end - duration_in_min.minutes

      slots = []

      while possible_slot_start <= last_possible_slot_start
        slots << Creneau.new(
          starts_at: possible_slot_start,
          motif: motif,
          duration_in_min:,
          lieu_id: plage_ouverture.lieu_id,
          agent: plage_ouverture.agent
        )
        possible_slot_start += duration_in_min.minutes
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

    def import_absences_from_caldav(agents)
      agents.each do |agent|
        if agent.caldav_configured?
          Caldav::ImportAbsencesFromCaldavJob.perform_later(agent.id)
        end
      end
    end
  end

  class BusyTimePreloader
    def initialize(range, agent, work_on_off_days)
      @range = range
      @agent = agent
      @work_on_off_days = work_on_off_days
      start_loading!
    end

    # On charge les absences en asynchrone et les rdvs en synchrone
    def self.start_loading_busy_times_for(range, agent, work_on_off_days:)
      new(range, agent, work_on_off_days)
    end

    def busy_times
      busy_times = @work_on_off_days ? [] : busy_times_from_off_days

      busy_times += busy_times_from_external_calendar

      busy_times += @rdvs_starts_and_ends_at.map do |rdv_starts_and_ends_at|
        BusyTime.new(rdv_starts_and_ends_at.first, rdv_starts_and_ends_at.last)
      end

      # Les absences sont encore chargées de manière asynchrone, donc on leur laisse le temps de charger
      busy_times += busy_times_from_absences

      # Le tri est nécessaire, surtout pour les surcharges.
      busy_times.sort_by(&:starts_at)
    end

    private

    def start_loading!
      # c'est là que l'on execute le SQL
      # TODO : Peut-être cacher la récupération de l'ensemble des RDV et absences concernées (pour n'avoir que deux requêtes) puis faire des selections dessus pour le filtre sur le range
      #        Le problème potentiel de cette approche est qu'il serait difficile d'éviter de charger des rdv et absences qui sont en dehors des ocurrences des plages d'ouverture

      @absences = @agent.absences.not_expired.in_range(@range).load_async

      @rdvs_starts_and_ends_at = optimized_rdv_request.pluck(:calculator_rdv_starts_at, :calculator_rdv_ends_at)
    end

    def optimized_rdv_request
      # Cet requête est censée utiliser l'index "calculator_index"
      AgentsRdv
        .where(agent_id: @agent.id, calculator_rdv_not_cancelled_and_in_the_future: true)
        .where("tsrange(calculator_rdv_starts_at, calculator_rdv_ends_at, '[)') && tsrange(?, ?)", @range.begin, @range.end)
        .select(:calculator_rdv_starts_at, :calculator_rdv_ends_at)
    end

    def busy_times_from_absences
      busy_times = []
      @absences.each do |absence|
        absence.occurrences_for(@range).each do |absence_occurrence|
          next if absence_out_of_range?(absence_occurrence)

          busy_times << BusyTime.new(absence_occurrence.starts_at, absence_occurrence.ends_at)
        end
      end
      busy_times
    end

    def absence_out_of_range?(absence)
      absence.ends_at < @range.begin || @range.end < absence.starts_at
    end

    def busy_times_from_external_calendar
      return [] unless @agent.caldav_configured?

      external_calendar_occurrences = []
      ExternalCalendarEvent.where(agent_id: @agent.id).within_range(@range).each do |event|
        event.all_occurrences_within(@range).each do |occurrence|
          external_calendar_occurrences << BusyTime.new(occurrence.starts_at, occurrence.ends_at)
        end
      end
      external_calendar_occurrences
    end

    def busy_times_from_off_days
      OffDays.all_in_date_range(@range).map do |off_day|
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
