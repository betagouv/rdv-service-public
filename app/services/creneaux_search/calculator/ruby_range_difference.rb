class CreneauxSearch::Calculator::RubyRangeDifference
  def perform(ranges, busy_times)
    busy_times.sort_by!(&:end)
    ranges.map do |range|
      split_range_recursively(range, busy_times)
    end.flatten
  end

  private

  # On enlève les intervalles occupés d'un morceau de plage d'ouverture
  def split_range_recursively(range, busy_times)
    return [] if range.nil?
    return [range] if busy_times.empty?

    busy_time = busy_times.first

    first_range(range, busy_time) \
      + split_range_recursively(remaining_range(range, busy_time), busy_times - [busy_time])
  end

  def first_range(range, busy_time)
    return [range.begin..busy_time.begin] if range.begin < busy_time.begin && range.cover?(busy_time)

    []
  end

  def remaining_range(range, busy_time)
    return busy_time.end..range.end if range.cover?(busy_time)
    return range.begin..busy_time.begin if range.cover?(busy_time.begin)
    return busy_time.end..range.end if range.cover?(busy_time.end)

    range if (busy_time.end < range.begin) || (busy_time.begin > range.end) # Dans ce dernier cas il n'y a pas d'overlap du tout entre le range et le busy_time
  end
end
