module CreneauxSearch::Calculator::MultirangeSerializer
  def self.datetime_ranges_to_pg_tsmultirange(datetime_ranges)
    return "tsmultirange()" if datetime_ranges.empty?

    multiranges = []
    datetime_ranges.each_slice(100) do |slice| # The Postgres initializer can't take more than 100 arguments
      multiranges << slice.map { |range| ActiveRecord::Base.sanitize_sql_array(["tsrange(?, ?, '[]')", range.begin, range.end]) }.join(", ")
    end

    multiranges.map { |multirange_arguments| "tsmultirange(#{multirange_arguments})" }.join("+")
  end
end
