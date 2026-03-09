module CreneauxSearch::Calculator
  class SplitFreeTimeRangesIntoCreneaux
    def initialize(free_times_po, motif, duration_in_min:)
      @free_times_po = free_times_po
      @motif = motif
      @duration_in_min = duration_in_min
    end

    attr_reader :free_times_po, :motif, :duration_in_min

    def perform
      slots_for(free_times_po, motif, duration_in_min:).select do |slot|
        slot.starts_at >= datetime_range.begin
      end
    end

    private

    def slots_for(plage_ouverture_free_times, motif, duration_in_min: nil)
      slots = []
      plage_ouverture_free_times.each do |plage_ouverture, free_times|
        free_times.each do |free_time|
          slots += calculate_slots(free_time, motif, plage_ouverture, duration_in_min:)
        end
      end
      slots
    end

    def calculate_slots(free_time, motif, plage_ouverture, duration_in_min: nil)
      possible_slot_start = earliest_possible_slot_start(free_time)
      duration_in_min ||= motif.default_duration_in_min
      last_possible_slot_start = free_time.end - duration_in_min.minutes

      slots = []

      while possible_slot_start <= last_possible_slot_start
        slots << Creneau.new(
          starts_at: possible_slot_start,
          motif: motif,
          duration_in_min:,
          lieu_id: plage_ouverture.lieu_id,
          agent: plage_ouverture.agent
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
end
