# frozen_string_literal: true

module SlotsHelper
  def extract_uniq_slots_for_date_and_time(slots, date)
    slots.sort_by(&:starts_at).uniq(&:starts_at).group_by { |c| c.starts_at.to_date }.select { |k, _v| k == date }
  end
end
