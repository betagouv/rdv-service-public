module CreneauxSearch
  module Range
    class << self
      def reduce_range_to_delay(motif, date_range)
        return motif.booking_delay_range if date_range.nil?
        return nil unless motif.booking_delay_range.overlaps?(date_range)

        start_range = [motif.start_booking_delay, date_range.begin].max
        end_range = [motif.end_booking_delay, date_range.end].min
        start_range..end_range
      end

      def ensure_date_range_with_time(date_range)
        time_begin = date_range.begin.instance_of?(Date) ? date_range.begin.beginning_of_day : date_range.begin
        time_end = date_range.end.instance_of?(Date) ? date_range.end.end_of_day : date_range.end

        time_begin..time_end
      end

      def ensure_range_is_date(range)
        return range if range.begin.is_a?(Date) && range.end.is_a?(Date)

        range.begin.to_date..range.end.to_date
      end
    end
  end
end
