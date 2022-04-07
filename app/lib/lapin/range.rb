# frozen_string_literal: true

module Lapin
  module Range
    class << self
      def reduce_range_to_delay(motif, date_range)
        return nil unless motif.booking_delay_range.overlaps?(date_range)

        start_range = [motif.start_booking_delay, date_range.begin].max
        end_range = [motif.end_booking_delay, date_range.end].min
        start_range..end_range
      end

      def ensure_date_range_with_time(date_range)
        time_begin = date_range.begin.is_a?(Time) ? date_range.begin : date_range.begin.beginning_of_day
        time_begin = Time.zone.now if time_begin < Time.zone.now
        time_end = date_range.end.is_a?(Time) ? date_range.end : date_range.end.end_of_day

        time_begin..time_end
      end
    end
  end
end
