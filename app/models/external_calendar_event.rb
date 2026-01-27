class ExternalCalendarEvent < ApplicationRecord
  belongs_to :agent

  scope :within_range, lambda { |range|
    where("raw_ical IS NULL AND starts_at < ? AND ends_at > ?", range.end, range.begin).or(where.not(raw_ical: nil))
  }

  def recurring?
    !!raw_ical
  end

  def all_occurrences_within(range)
    if recurring?
      Ical::RruleExpander.new(raw_ical).compute_occurrences_within(range)
    elsif range.overlaps?(starts_at..ends_at)
      [Recurrence::Occurrence.new(starts_at:, ends_at:)]
    else
      []
    end
  end

  # On retire les champs pouvant contenir des données sensibles
  def raw_ical=(str)
    super(Ical::Scrubber.new(str).scrubbed)
  end
end
