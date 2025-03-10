module RecurrenceConcern
  extend ActiveSupport::Concern

  included do
    serialize :recurrence, coder: Montrose::Recurrence
    attribute :start_time, :time_only # uses Tod::TimeOfDayType
    attribute :end_time, :time_only   # uses Tod::TimeOfDayType

    before_save { self.recurrence_ends_at = recurrence&.ends_at&.end_of_day }

    validates :first_day, :start_time, :end_time, presence: true
    validate :recurrence_starts_matches_first_day, if: :recurring?
    validate :recurrence_ends_after_first_day, if: :recurring?

    scope :exceptionnelles, -> { where(recurrence: nil) }
    scope :regulieres, -> { where.not(recurrence: nil) }
    scope :overlapping_range, lambda { |range|
      in_range(range).select { _1.occurrences_for(range).any? { |occurrence| occurrence.overlaps?(range) } }
    }
  end

  class_methods do
    def serialize_for_active_job(record)
      manually_serialized_attrs = {
        start_time: record.start_time.to_s,
        end_time: record.end_time.to_s,
        recurrence: Montrose::Recurrence.dump(record.recurrence),
      }
      record.attributes.merge(manually_serialized_attrs.stringify_keys)
    end

    def deserialize_for_active_job(hash)
      hash = hash.symbolize_keys
      manually_deserialized_attrs = {
        start_time: Tod::TimeOfDay.parse(hash[:start_time]),
        end_time: Tod::TimeOfDay.parse(hash[:end_time]),
        recurrence: Montrose::Recurrence.load(hash[:recurrence]),
      }
      new(hash.merge(manually_deserialized_attrs))
    end
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

  def recurrence=(hash)
    super(hash.presence) # on évite d'avoir un objet Montrose::Recurrence avec une config vide
  end

  def duration
    (first_occurrence_ends_at - starts_at).to_i
  end

  def exceptionnelle?
    !recurring?
  end

  def recurring?
    recurrence.present?
  end

  def occurrences_for(inclusive_date_range)
    return [] if inclusive_date_range.nil?

    occurrence_start_at_list_for(inclusive_date_range).map do |o|
      Recurrence::Occurrence.new(starts_at: o, ends_at: o + duration)
    end
  end

  def human_time_range
    [human_time(starts_at), human_time(ends_at)].join("-")
  end

  def human_time(datetime)
    minutes = datetime.min.zero? ? nil : datetime.min
    "#{datetime.hour}h#{minutes}"
  end

  class_methods do
    def all_occurrences_for(period)
      # defined as a class method, but typically used on ActiveRecord::Relation
      current_scope ||= all

      current_scope.in_range(period).flat_map do |element|
        element.occurrences_for(period).map { |occurrence| [element, occurrence] }
      end.sort_by(&:second)
    end
  end

  private

  def occurrence_start_at_list_for(inclusive_date_range)
    datetime_range_start = inclusive_date_range.begin.is_a?(Date) ? inclusive_date_range.begin.in_time_zone.beginning_of_day : inclusive_date_range.begin

    inclusive_datetime_range = datetime_range_start..(inclusive_date_range.end.end_of_day)

    if recurring?
      min_until = [inclusive_date_range.end, recurrence_ends_at].compact.min.end_of_day

      rec = recurrence.starting(starts_at).until(min_until)

      if starts_at <= inclusive_datetime_range.begin
        rec = rec.fast_forward(inclusive_datetime_range.begin)
      end

      rec.lazy.select do |occurrence_starts_at|
        event_in_range?(occurrence_starts_at, occurrence_starts_at + duration, inclusive_datetime_range)
      end.to_a
    else
      event_in_range?(starts_at, ends_at, inclusive_datetime_range) ? [starts_at] : []
    end
  end

  def event_in_range?(event_starts_at, event_ends_at, range)
    (event_starts_at..event_ends_at).overlap?(range)
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
