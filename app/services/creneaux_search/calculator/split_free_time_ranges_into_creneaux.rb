class CreneauxSearch::Calculator::SplitFreeTimeRangesIntoCreneaux
  def initialize(free_time_ranges, duration_in_min:, minutes_after_rdvs:)
    @free_time_ranges = free_time_ranges
    @duration_in_min = duration_in_min
    @minutes_after_rdvs = minutes_after_rdvs
  end

  def perform(search_datetime_range)
    slots = []

    @free_time_ranges.each do |free_time|
      slots += calculate_slots(free_time)
    end

    slots.select do |slot|
      slot.starts_at >= search_datetime_range.begin
    end
  end

  private

  def calculate_slots(free_time)
    possible_slot_start = earliest_possible_slot_start(free_time)

    rdv_duration_for_agent = @duration_in_min.minutes + @minutes_after_rdvs.minutes
    last_possible_slot_start = free_time.end - rdv_duration_for_agent

    slots = []

    while possible_slot_start <= last_possible_slot_start
      slots << Creneau.new(
        starts_at: possible_slot_start,
        duration_in_min: @duration_in_min,
        minutes_after_rdv: @minutes_after_rdvs
      )
      possible_slot_start += rdv_duration_for_agent
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
end
