class CreneauxSearch::Calculator::SplitFreeTimeRangesIntoCreneaux
  def initialize(free_time_ranges, motif, plage_ouverture, duration_in_min:)
    @free_time_ranges = free_time_ranges
    @motif = motif
    @plage_ouverture = plage_ouverture
    @duration_in_min = duration_in_min
  end

  def perform(datetime_range)
    slots = []

    @free_time_ranges.each do |free_time|
      slots += calculate_slots(free_time, duration_in_min:)
    end

    slots.select do |slot|
      slot.starts_at >= datetime_range.begin
    end
  end

  private

  attr_reader :free_times_po, :motif, :duration_in_min

  def calculate_slots(free_time, duration_in_min: nil)
    possible_slot_start = earliest_possible_slot_start(free_time)
    duration_in_min ||= @motif.default_duration_in_min
    last_possible_slot_start = free_time.end - duration_in_min.minutes

    slots = []

    while possible_slot_start <= last_possible_slot_start
      slots << Creneau.new(
        starts_at: possible_slot_start,
        motif: @motif,
        duration_in_min:,
        lieu_id: @plage_ouverture.lieu_id,
        agent: @plage_ouverture.agent
      )
      possible_slot_start += duration_in_min.minutes
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
