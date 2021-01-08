class TimeSlot
  class DifferentDatesError < StandardError; end

  class OutOfOrderTimesError < StandardError; end

  attr_reader :starts_at, :ends_at

  def initialize(starts_at, ends_at)
    raise DifferentDatesError if starts_at.to_date != ends_at.to_date
    raise OutOfOrderTimesError if starts_at >= ends_at

    @starts_at = starts_at
    @ends_at = ends_at
  end

  def intersects?(other_time_slot)
    to_date == other_time_slot.to_date &&
      start_time < other_time_slot.end_time &&
      end_time > other_time_slot.start_time
  end

  def start_time
    starts_at.to_time_of_day
  end

  def end_time
    ends_at.to_time_of_day
  end

  def to_date
    starts_at.to_date
  end
end
