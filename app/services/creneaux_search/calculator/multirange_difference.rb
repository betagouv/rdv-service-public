class CreneauxSearch::Calculator::MultirangeDifference
  # available_ranges: array of datetime ranges, e.g. [(Time.zone.now..1.hour.from_now), (24.hours.from_now..25.hours.from_now)]
  # busy_times: array of BusyTimes
  # The return value is also the same type
  def perform(available_ranges, busy_ranges)
    pg_available_ranges = datetime_ranges_to_pg_tsmultirange(available_ranges)
    pg_busy_ranges = datetime_ranges_to_pg_tsmultirange(busy_ranges)

    result = ActiveRecord::Base.connection.execute("SELECT (#{ActiveRecord::Base.sanitize_sql(pg_available_ranges)}) - (#{ActiveRecord::Base.sanitize_sql(pg_busy_ranges)})")

    parse_pg_tsmultirange(result.getvalue(0, 0))
  end

  def datetime_ranges_to_pg_tsmultirange(datetime_ranges)
    return "tsmultirange()" if datetime_ranges.empty?

    multiranges = []
    datetime_ranges.each_slice(100) do |slice| # The Postgres initializer can't take more than 100 arguments
      multiranges << slice.map { |range| ActiveRecord::Base.sanitize_sql_array(["tsrange(?, ?, '[]')", range.begin, range.end]) }.join(", ")
    end

    multiranges.map { |multirange_arguments| "tsmultirange(#{multirange_arguments})" }.join("+")
  end

  private

  def parse_pg_tsmultirange(pg_string)
    pg_string.scan(/\{*[\[|\(](.*?)?,(.*?)?[\]|\)]/).map do |range|
      (parse_pg_timestamp(range[0])..parse_pg_timestamp(range[1]))
    end
  end

  def parse_pg_timestamp(pg_ts_string)
    Time.find_zone("UTC").parse(pg_ts_string).in_time_zone(Time.zone.name)
  end
end
