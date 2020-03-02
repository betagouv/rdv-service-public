module RecurrenceConcern
  extend ActiveSupport::Concern

  included do
    require "montrose"

    serialize :recurrence, Montrose::Recurrence
    serialize :start_time, Tod::TimeOfDay
    serialize :end_time, Tod::TimeOfDay

    before_save :clear_empty_recurrence

    validates :first_day, :start_time, :end_time, presence: true

    scope :exceptionnelles, -> { where(recurrence: nil) }
    scope :regulieres, -> { where.not(recurrence: nil) }
  end

  def starts_at
    start_time&.on(first_day)
  end

  def ends_at
    if defined?(end_day) && end_day.present?
      end_time.on(end_day)
    else
      end_time&.on(first_day)
    end
  end

  def duration
    (ends_at - starts_at).to_i
  end

  def exceptionnelle?
    recurrence.nil?
  end

  def occurences_for(inclusive_date_range)
    recurrence_until = recurrence&.to_hash&.[](:until)
    min_until = [inclusive_date_range.end, recurrence_until].compact.min.to_time.end_of_day

    inclusive_datetime_range = (inclusive_date_range.begin.to_time)..(inclusive_date_range.end.end_of_day)
    results = if recurrence.present?
                recurrence.starting(starts_at).until(min_until).lazy.select { |occurrence_starts_at| event_in_range?(occurrence_starts_at, occurrence_starts_at + duration, inclusive_datetime_range) }.to_a
              else
                [starts_at].select { |_t| event_in_range?(starts_at, ends_at, inclusive_datetime_range) }
              end
    results.map { |o| Recurrence::Occurrence.new(starts_at: o, ends_at: o + duration) }
  end

  def occurences_ranges_for(inclusive_date_range)
    occurences_for(inclusive_date_range).map do |occurence|
      occurence.starts_at..(occurence.ends_at)
    end
  end

  private

  def event_in_range?(event_starts_at, event_ends_at, range)
    range.cover?(event_starts_at) || range.cover?(event_ends_at) || (event_starts_at < range.begin && range.end < event_ends_at)
  end

  def clear_empty_recurrence
    self.recurrence = nil if recurrence.present? && recurrence.to_hash == {}
  end
end
