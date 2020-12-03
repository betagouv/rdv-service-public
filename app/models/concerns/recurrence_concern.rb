module RecurrenceConcern
  extend ActiveSupport::Concern

  included do
    require "montrose"

    serialize :recurrence, Montrose::Recurrence
    serialize :start_time, Tod::TimeOfDay
    serialize :end_time, Tod::TimeOfDay

    before_save :clear_empty_recurrence

    validates :first_day, :start_time, :end_time, presence: true
    validate :recurrence_starts_matches_first_day, if: :recurring?

    scope :exceptionnelles, -> { where(recurrence: nil) }
    scope :regulieres, -> { where.not(recurrence: nil) }
  end

  def starts_at
    return nil if start_time.blank? || first_day.blank?

    start_time&.on(first_day)
  end

  def ends_at
    if end_time.blank?
      nil
    elsif recurring?
      recurrence_until.present? ? end_time.on(recurrence_until.to_date) : nil
    elsif defined?(end_day) && end_day.present?
      end_time.on(end_day)
    else
      first_day.present? ? end_time.on(first_day) : nil
    end
  end

  def first_occurence_ends_at
    if end_time.blank?
      nil
    elsif defined?(end_day) && end_day.present?
      end_time.on(end_day)
    else
      first_day.present? ? end_time.on(first_day) : nil
    end
  end

  def duration
    (first_occurence_ends_at - starts_at).to_i
  end

  def exceptionnelle?
    recurrence.nil?
  end

  def recurring?
    recurrence.present?
  end

  def occurences_for(inclusive_date_range)
    return [] if inclusive_date_range.nil?

    occurence_start_at_list_for(inclusive_date_range)
      .map { |o| Recurrence::Occurrence.new(starts_at: o, ends_at: o + duration) }
  end

  def recurrence_opts
    { interval: 1 }.merge(recurrence.default_options.to_h)
  end

  def recurrence_until
    recurrence&.to_hash&.[](:until)
  end

  def recurrence_interval
    return nil if recurrence.nil?

    recurrence.to_hash[:interval] || 1 # when interval is nil, it means 1
  end

  private

  def occurence_start_at_list_for(inclusive_date_range)
    min_until = [inclusive_date_range.end, recurrence_until].compact.min.to_time.end_of_day
    inclusive_datetime_range = (inclusive_date_range.begin.to_time)..(inclusive_date_range.end.end_of_day)
    if recurring?
      recurrence.starting(starts_at).until(min_until).lazy.select do |occurrence_starts_at|
        event_in_range?(occurrence_starts_at, occurrence_starts_at + duration, inclusive_datetime_range)
      end.to_a
    else
      event_in_range?(starts_at, first_occurence_ends_at, inclusive_datetime_range) ? [starts_at] : []
    end
  end

  def event_in_range?(event_starts_at, event_ends_at, range)
    range.cover?(event_starts_at) || range.cover?(event_ends_at) || (event_starts_at < range.begin && range.end < event_ends_at)
  end

  def clear_empty_recurrence
    self.recurrence = nil if recurrence.present? && recurrence.to_hash == {}
  end

  def recurrence_starts_matches_first_day
    return true if recurrence.to_h[:starts]&.to_date == first_day

    errors.add(:base, "Le début de la récurrence ne correspond pas au premier jour.")
  end
end
