class CreneauxSearch::Calculator::FreeTimesFromPlageOuvertureAndBusyTimes
  def initialize(search_datetime_range, plage_ouverture, work_on_off_days:, duration_in_min:)
    @search_datetime_range = search_datetime_range
    @plage_ouverture = plage_ouverture
    @agent = plage_ouverture.agent
    @work_on_off_days = work_on_off_days
    @duration_in_min = duration_in_min
  end

  def perform(ruby_diff:)
    @available_ranges = plage_ouverture_occurrence_ranges
    return [] if @available_ranges.empty?

    busy_times = @work_on_off_days ? [] : busy_times_from_off_days

    busy_times += busy_times_from_external_calendar
    busy_times += busy_times_from_absences
    busy_times += busy_times_from_rdvs

    if ruby_diff
      CreneauxSearch::Calculator::RubyRangeDifference.new.perform(@available_ranges, busy_times)
    else
      (MultiRange.new(@available_ranges) - MultiRange.new(busy_times)).ranges
    end
  end

  private

  def plage_ouverture_occurrence_ranges
    occurrences = @plage_ouverture.occurrences_for(@search_datetime_range)

    occurrences.map do |occurrence|
      next if occurrence.ends_at < Time.zone.now

      occurrence.starts_at..occurrence.ends_at
    end.compact
  end

  def busy_times_from_off_days
    @available_ranges.map do |range|
      OffDays.all_in_date_range(range).map(&:all_day)
    end.flatten
  end

  def busy_times_from_external_calendar
    return [] unless @agent.caldav_configured?

    external_calendar_occurrences = []
    @available_ranges.each do |range|
      ExternalCalendarEvent.where(agent_id: @agent.id).within_range(range).each do |event|
        event.all_occurrences_within(range).each do |occurrence|
          external_calendar_occurrences << (occurrence.starts_at..occurrence.ends_at)
        end
      end
    end
    external_calendar_occurrences
  end

  def busy_times_from_absences
    busy_times = []

    absences = @agent.absences.not_expired.in_range(@available_ranges.first.begin..@availabled_ranges.last.end)

    absences.each do |absence|
      absence.occurrences_for(range).each do |absence_occurrence|
        next if absence_out_of_range?(absence_occurrence, range)

        busy_times << (absence_occurrence.starts_at..absence_occurrence.ends_at)
      end
    end

    busy_times
  end

  def absence_out_of_range?(absence, range)
    absence.ends_at < range.begin || range.end < absence.starts_at
  end

  def busy_times_from_rdvs
    optimized_rdv_request.pluck(:calculator_rdv_starts_at, :calculator_rdv_ends_at).map do |starts_at, ends_at|
      (starts_at..ends_at)
    end
  end

  def optimized_rdv_request
    # Cette requête est censée utiliser l'index "calculator_index"

    multiranges_union_in_sql = CreneauxSearch::Calculator::MultirangeDifference.new.datetime_ranges_to_pg_tsmultirange(@available_ranges)

    AgentsRdv
      .where(agent_id: @agent.id, calculator_rdv_not_cancelled_and_in_the_future: true)
      .where("tsrange(calculator_rdv_starts_at, calculator_rdv_ends_at, '[)') && (#{ActiveRecord::Base.sanitize_sql(multiranges_union_in_sql)})")
      .select(:calculator_rdv_starts_at, :calculator_rdv_ends_at)
  end
end
