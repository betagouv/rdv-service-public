class CreneauxSearch::Calculator::FreeTimesFromPlageOuvertureAndBusyTimes
  def initialize(search_datetime_range, plage_ouverture, work_on_off_days:)
    @search_datetime_range = search_datetime_range
    @plage_ouverture = plage_ouverture
    @agent = plage_ouverture.agent
    @work_on_off_days = work_on_off_days
  end

  def perform
    available_ranges = plage_ouverture_occurrence_ranges

    return [] if available_ranges.empty?

    max_availability_range = available_ranges.first.begin..available_ranges.last.end

    busy_times = busy_times_from_off_days(max_availability_range)
    busy_times += busy_times_from_external_calendar(max_availability_range)
    busy_times += busy_times_from_absences(max_availability_range)
    busy_times += busy_times_from_rdvs(available_ranges)

    (MultiRange.new(available_ranges) - MultiRange.new(busy_times)).ranges
  end

  private

  def plage_ouverture_occurrence_ranges
    occurrences = @plage_ouverture.occurrences_for(@search_datetime_range)

    occurrences.map do |occurrence|
      next if occurrence.ends_at < Time.zone.now

      occurrence.starts_at...occurrence.ends_at
    end.compact
  end

  def busy_times_from_off_days(max_availability_range)
    return [] if @work_on_off_days

    OffDays.all_in_date_range(max_availability_range).map(&:all_day)
  end

  def busy_times_from_external_calendar(max_availability_range)
    return [] unless @agent.caldav_configured?

    external_calendar_occurrences = []

    ExternalCalendarEvent.where(agent_id: @agent.id).within_range(max_availability_range).each do |event|
      event.all_occurrences_within(range).each do |occurrence|
        external_calendar_occurrences << (occurrence.starts_at...occurrence.ends_at)
      end
    end

    external_calendar_occurrences
  end

  def busy_times_from_absences(max_availability_range)
    busy_times = []

    absences = @agent.absences.not_expired.in_range(max_availability_range)

    absences.each do |absence|
      absence.occurrences_for(max_availability_range).each do |absence_occurrence|
        busy_times << (absence_occurrence.starts_at...absence_occurrence.ends_at)
      end
    end

    busy_times
  end

  def busy_times_from_rdvs(available_ranges)
    optimized_rdv_request(available_ranges).pluck(:calculator_rdv_starts_at, :calculator_rdv_ends_at).map do |starts_at, ends_at|
      (starts_at...ends_at)
    end
  end

  def optimized_rdv_request(available_ranges)
    multiranges_union_in_sql = datetime_ranges_to_pg_tsmultirange(available_ranges)

    # Cette requête est censée utiliser l'index "calculator_index"
    AgentsRdv
      .where(agent_id: @agent.id, calculator_rdv_not_cancelled_and_in_the_future: true)
      .where("tsrange(calculator_rdv_starts_at, calculator_rdv_ends_at, '[)') && (#{ActiveRecord::Base.sanitize_sql(multiranges_union_in_sql)})")
      .select(:calculator_rdv_starts_at, :calculator_rdv_ends_at)
  end

  def datetime_ranges_to_pg_tsmultirange(datetime_ranges)
    return "tsmultirange()" if datetime_ranges.empty?

    pg_multiranges = []
    datetime_ranges.each_slice(100) do |slice| # The Postgres initializer can't take more than 100 arguments
      pg_multiranges << slice.map { |range| ActiveRecord::Base.sanitize_sql_array(["tsrange(?, ?, '[]')", range.begin, range.end]) }.join(", ")
    end

    pg_multiranges.map { |multirange_arguments| "tsmultirange(#{multirange_arguments})" }.join("+")
  end
end
