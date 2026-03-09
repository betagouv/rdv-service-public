module CreneauxSearch::Calculator
  class FreeTimesFromPlageOuvertureAndBusyTimes
    def initialize(search_datetime_range, work_on_off_days:)
      @search_datetime_range = search_datetime_range
      @work_on_off_days = work_on_off_days
    end

    def perform(plages_ouvertures)
      # pseudo-code :
      # charger toutes les occurrences de la plage_ouverture
      #
      # si applicable, supprimer celles pendant les jours fériés et dimanches
      #
      # charger les absences sur le range et calculer leurs occurrences
      #
      # faire une tsmultirange soustraction pour les absences
      #
      # charger les occurrences de agentsrdvs concernés
      # faire une tsmultirange soustraction sur le résultat pour les agentsrdvs
      #
      # idem pour les indispos caldav
      #
      # découper le range résultant en créneaux

      free_times = {}
      plages_ouvertures.each do |plage_ouverture|
        free_times[plage_ouverture] = calculate_free_times(plage_ouverture, work_on_off_days:)
      end
      free_times.select { |_, v| v&.any? }
    end

    private

    attr_reader :work_on_off_days

    def calculate_free_times(plage_ouverture, work_on_off_days:)
      ranges = occurrence_ranges_for(plage_ouverture)
      return [] if ranges.empty?

      busy_times = BusyTimePreloader.start_loading_busy_times_for(ranges, plage_ouverture.agent, work_on_off_days:).busy_times

      CreneauxSearch::Calculator::MultirangeDifference.new.perform(ranges, busy_times.map(&:range))
    end

    def occurrence_ranges_for(plage_ouverture)
      occurrences = plage_ouverture.occurrences_for(@search_datetime_range)

      occurrences.map do |occurrence|
        next if occurrence.ends_at < Time.zone.now

        occurrence.starts_at..occurrence.ends_at
      end.compact
    end

    class BusyTimePreloader
      def initialize(ranges, agent, work_on_off_days)
        @ranges = ranges
        @agent = agent
        @work_on_off_days = work_on_off_days
        start_loading!
      end

      # On charge les absences en asynchrone et les rdvs en synchrone
      def self.start_loading_busy_times_for(ranges, agent, work_on_off_days:)
        new(ranges, agent, work_on_off_days)
      end

      def busy_times
        busy_times = @work_on_off_days ? [] : busy_times_from_off_days

        busy_times += busy_times_from_external_calendar

        busy_times += @rdvs_starts_and_ends_at.map do |rdv_starts_and_ends_at|
          BusyTime.new(rdv_starts_and_ends_at.first, rdv_starts_and_ends_at.last)
        end

        # Les absences sont encore chargées de manière asynchrone, donc on leur laisse le temps de charger
        busy_times + busy_times_from_absences
      end

      private

      def start_loading!
        # c'est là que l'on execute le SQL
        # TODO : Peut-être cacher la récupération de l'ensemble des RDV et absences concernées (pour n'avoir que deux requêtes) puis faire des selections dessus pour le filtre sur le range
        #        Le problème potentiel de cette approche est qu'il serait difficile d'éviter de charger des rdv et absences qui sont en dehors des ocurrences des plages d'ouverture

        @absences_by_range = @ranges.index_with do |range|
          @agent.absences.not_expired.in_range(range).load_async
        end

        @rdvs_starts_and_ends_at = optimized_rdv_request.pluck(:calculator_rdv_starts_at, :calculator_rdv_ends_at)
      end

      def optimized_rdv_request
        # Cet requête est censée utiliser l'index "calculator_index"
        #
        #
        # On construit plusieurs multirange, parce que la fonction du contructeur ne peut pas prendre plus de 100 ranges en arguments

        multiranges = []
        @ranges.each_slice(100) do |slice|
          multiranges << slice.map { |range| ActiveRecord::Base.sanitize_sql_array(["tsrange(?, ?, '[]')", range.begin, range.end]) }.join(", ")
        end

        multiranges_union_in_sql = multiranges.map { |multirange_arguments| "tsmultirange(#{multirange_arguments})" }.join("+")

        AgentsRdv
          .where(agent_id: @agent.id, calculator_rdv_not_cancelled_and_in_the_future: true)
          .where("tsrange(calculator_rdv_starts_at, calculator_rdv_ends_at, '[)') && (#{ActiveRecord::Base.sanitize_sql(multiranges_union_in_sql)})")
          .select(:calculator_rdv_starts_at, :calculator_rdv_ends_at)
      end

      def busy_times_from_absences
        busy_times = []
        @absences_by_range.each do |range, absences|
          absences.each do |absence|
            absence.occurrences_for(range).each do |absence_occurrence|
              next if absence_out_of_range?(absence_occurrence, range)

              busy_times << BusyTime.new(absence_occurrence.starts_at, absence_occurrence.ends_at)
            end
          end
        end
        busy_times
      end

      def absence_out_of_range?(absence, range)
        absence.ends_at < range.begin || range.end < absence.starts_at
      end

      def busy_times_from_external_calendar
        return [] unless @agent.caldav_configured?

        external_calendar_occurrences = []
        @ranges.each do |range|
          ExternalCalendarEvent.where(agent_id: @agent.id).within_range(range).each do |event|
            event.all_occurrences_within(range).each do |occurrence|
              external_calendar_occurrences << BusyTime.new(occurrence.starts_at, occurrence.ends_at)
            end
          end
        end
        external_calendar_occurrences
      end

      def busy_times_from_off_days
        @ranges.map do |range|
          OffDays.all_in_date_range(range).map do |off_day|
            BusyTime.new(off_day.beginning_of_day, off_day.end_of_day)
          end
        end.flatten
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
end
