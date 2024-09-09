module RecurrenceConcern
  extend ActiveSupport::Concern

  included do
    serialize :recurrence, Montrose::Recurrence
    serialize :start_time, Tod::TimeOfDay
    serialize :end_time, Tod::TimeOfDay

    before_save :clear_empty_recurrence, :set_recurrence_ends_at

    validates :first_day, :start_time, :end_time, presence: true
    validate :recurrence_starts_matches_first_day, if: :recurring?
    validate :recurrence_ends_after_first_day, if: :recurring?

    scope :exceptionnelles, -> { where(recurrence: nil) }
    scope :regulieres, -> { where.not(recurrence: nil) }
    scope :overlapping_range, lambda { |range|
      in_range(range).select { _1.occurrences_for(range).any? { |occurence| occurence.overlaps?(range) } }
    }
  end

  def starts_at
    return nil if start_time.blank? || first_day.blank?

    start_time&.on(first_day)
  end

  def ends_at
    if end_time.blank?
      nil
    elsif recurring?
      recurrence_ends_at.present? ? end_time.on(recurrence_ends_at.to_date) : nil
    elsif defined?(end_day) && end_day.present?
      end_time.on(end_day)
    else
      first_day.present? ? end_time.on(first_day) : nil
    end
  end

  def first_occurrence_ends_at
    if end_time.blank?
      nil
    elsif defined?(end_day) && end_day.present?
      end_time.on(end_day)
    else
      first_day.present? ? end_time.on(first_day) : nil
    end
  end

  def duration
    (first_occurrence_ends_at - starts_at).to_i
  end

  def exceptionnelle?
    recurrence.nil?
  end

  def recurring?
    recurrence.present?
  end

  def occurrences_for(inclusive_date_range, only_future: false)
    return [] if inclusive_date_range.nil?

    occurrence_start_at_list_for(inclusive_date_range, only_future: only_future)
      .map { |o| Recurrence::Occurrence.new(starts_at: o, ends_at: o + duration) }
  end

  # @return [ActiveSupport::TimeWithZone, nil] the earliest future occurrence at the time of computation
  def earliest_future_occurrence_time(refresh: false)
    return unless recurring?

    cache_key = "earliest_future_occurrence_#{self.class.table_name}_#{id}_#{updated_at}"

    Rails.cache.fetch(cache_key, force: refresh, expires_in: 1.week) do
      recurrence.starting(starts_at).until(recurrence_ends_at).lazy.find do |occurrence|
        (occurrence + duration).future? # On vérifie la date de fin de l'occurence, car on veut voir les créneaux d'une occurrence en cours
      end
    end
  end

  def recurrence_interval
    return nil if recurrence.nil?

    recurrence.to_hash[:interval] || 1 # when interval is nil, it means 1
  end

  class_methods do
    def all_occurrences_for(period)
      # defined as a class method, but typically used on ActiveRecord::Relation
      current_scope ||= all
      current_scope.flat_map do |element|
        element.occurrences_for(period).map { |occurrence| [element, occurrence] }
      end.sort_by(&:second)
    end
  end

  private

  # The `only_future` param was introduced to circumvent performance
  # issues with Montrose's occurrence generation.
  # It uses a recent occurrence as a starting point
  # when computing future occurrences, which is faster
  # than starting form the very first occurrence.
  # The value of a recent occurrence is computed and cached in #earliest_future_occurrence_time.
  # Warning: using `only_future: true` will only yield future occurrences, not past ones.
  def occurrence_start_at_list_for(inclusive_date_range, only_future:)
    inclusive_datetime_range = (inclusive_date_range.begin)..(inclusive_date_range.end.end_of_day)

    if recurring?
      min_from = [start_time.on(inclusive_date_range.begin), starts_at].max
      min_until = [inclusive_date_range.end, recurrence_ends_at].compact.min.end_of_day

      # L'appel à .starting(starts_at) permet d'initialiser correctement l'heure de départ
      recurrence.starting(starts_at).between(min_from..min_until).lazy.select do |occurrence_starts_at|
        event_in_range?(occurrence_starts_at, occurrence_starts_at + duration, inclusive_datetime_range)
      end.to_a
    else
      event_in_range?(starts_at, first_occurrence_ends_at, inclusive_datetime_range) ? [starts_at] : []
    end
  end

  def event_in_range?(event_starts_at, event_ends_at, range)
    range.cover?(event_starts_at) || range.cover?(event_ends_at) || (event_starts_at < range.begin && range.end < event_ends_at)
  end

  def set_recurrence_ends_at
    self.recurrence_ends_at = recurrence&.ends_at&.end_of_day
  end

  def clear_empty_recurrence
    self.recurrence = nil if recurrence.present? && recurrence.to_hash == {}
  end

  def recurrence_starts_matches_first_day
    return true if recurrence.to_h[:starts]&.to_date == first_day

    errors.add(:base, "Le début de la récurrence ne correspond pas au premier jour.")
  end

  def recurrence_ends_after_first_day
    return true if recurrence.ends_at.nil?
    return true if recurrence.ends_at.to_date > first_day

    errors.add(:base, "La fin de la récurrence doit être après le premier jour.")
  end
end
