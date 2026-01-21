class ExternalCalendarEvent < ApplicationRecord
  belongs_to :agent

  scope :within_range, lambda { |range|
    where("raw_ical IS NULL AND starts_at < ? AND ends_at > ?", range.end, range.begin).or(where.not(raw_ical: nil))
  }

  def recurring?
    !!raw_ical
  end

  def within?(range)
    range.overlaps?(starts_at..ends_at)
  end

  def all_occurrences_within(range)
    if recurring?
      Caldav::RruleExpander.new(raw_ical).all_occurrences_within(range)
    elsif within?(range)
      [Recurrence::Occurrence.new(starts_at:, ends_at:)]
    else
      []
    end
  end
end
