module RecurrenceConcern
  extend ActiveSupport::Concern

  DAYS = %i[
    monday_start_time
    monday_end_time
    tuesday_start_time
    tuesday_end_time
    wednesday_start_time
    wednesday_end_time
    thursday_start_time
    thursday_end_time
    friday_start_time
    friday_end_time
    saturday_start_time
    saturday_end_time
  ].freeze

  ATTRIBUTES = [:has_recurrence, :recurrence_type, :until_mode, :interval, :every, :on, :until, :ends, :total, :day, *DAYS].freeze

  included do
    store :recurrence, coder: JSON, accessors: RecurrenceConcern::ATTRIBUTES

    serialize :start_time, Tod::TimeOfDay
    serialize :end_time, Tod::TimeOfDay

    before_save :set_recurrence_ends_at, if: -> { recurrence.present? }
    before_save :set_data_for_monthly_recurrence, if: -> { recurrence.present? }

    validates :first_day, :start_time, :end_time, presence: true
    validate :recurrence_ends_after_first_day, if: :recurring?

    scope :exceptionnelles, -> { where(recurrence: nil) }
    scope :regulieres, -> { where.not(recurrence: nil) }
    scope :overlapping_range, lambda { |range|
      in_range(range).select { _1.occurrences_for(range).any? { |occurence| occurence.overlaps?(range) } }
    }
  end

  def schedule
    return nil if every.blank?

    @schedule ||= Lapin::Schedule.new(self)
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
    schedule.blank?
  end

  def recurring?
    schedule.present?
  end

  def occurrences_for(date_range, only_future: false)
    return [] if date_range.nil?

    if schedule
      schedule.occurences(date_range: date_range, only_future: only_future)
    elsif event_in_range?(starts_at, first_occurrence_ends_at, range)
      Recurrence::Occurrence.new(starts_at: starts, ends_at: starts_at + duration)
    else
      []
    end
  end

  # @return [ActiveSupport::TimeWithZone, nil] the earliest future occurrence at the time of computation
  def earliest_future_occurrence_time(refresh: false)
    return unless recurring?

    cache_key = "earliest_future_occurrence_#{self.class.table_name}_#{id}_#{updated_at}"
    Rails.cache.fetch(cache_key, force: refresh, expires_in: 1.week) do
      schedule.next_future_event
    end
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

  def event_in_range?(event_starts_at, event_ends_at, range)
    range.cover?(event_starts_at) || range.cover?(event_ends_at) || (event_starts_at < range.begin && range.end < event_ends_at)
  end

  def set_recurrence_ends_at
    if recurrence[:until].present?  && !recurrence[:until].starts_with?("__/") # Date de fin de la récurrence
      self.recurrence_ends_at = recurrence[:ends_at].end_of_day
    elsif recurrence[:total].present? # Nombre d'occurences de la récurrence
      # rubocop:disable Lint/UnreachableLoop
      self.recurrence_ends_at = schedule.events.reverse_each { |event| break event }.end_of_day
      # rubocop:enable Lint/UnreachableLoop
    end
  end

  def recurrence_ends_after_first_day
    return true if recurrence[:until].nil? || recurrence[:until].starts_with?("__/")
    return true if recurrence[:until].to_date > first_day

    errors.add(:base, "La fin de la récurrence doit être après le premier jour.")
  end

  def set_data_for_monthly_recurrence
    return unless recurrence[:has_recurrence].to_b && recurrence[:every] == "month"

    recurrence[:on] = []
    recurrence[:day] = { first_day.cwday => [week_day_position_in_month] }
  end

  def week_day_position_in_month
    (first_day.day - 1).div(7) + 1
  end
end
