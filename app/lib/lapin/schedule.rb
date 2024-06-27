module Lapin
  class Schedule
    InvalidRecurrenceData = Class.new(StandardError)
    attr_reader :schedule

    delegate :lazy, :include, to: :schedule

    def initialize(model)
      raise InvalidRecurrenceData if model.every.blank?

      @model = model
      @schedule = Montrose::Schedule.new(schedule_options)
    end

    delegate :to_h, to: :default_options

    def default_options
      @default_options ||= Montrose::Options.new(
        every: @model.recurrence[:every],
        interval: parse_int(@model.recurrence[:interval]),
        total: parse_int(@model.recurrence[:total]),
        on: active_days,
        starts: @model.first_day,
        until: parse_date(@model.recurrence[:until]),
        ends: parse_date(@model.recurrence[:ends]),
        day: parse_collection(@model.recurrence[:day])
      )
    end

    def ends_at
      Montrose::Recurrence.new(default_options).ends_at
    end

    def occurences(date_range:, only_future: false)
      params = {
        starts: only_future ? (@model.earliest_future_occurrence_time || @model.starts_at) : @model.starts_at,
        until: [date_range.end, @model.recurrence_ends_at].compact.min.end_of_day,
      }

      events(params: params).filter_map do |start_time|
        end_time = end_time_for(start_time)
        next unless date_range.cover?(start_time) || date_range.cover?(end_time) || (start_time < date_range.begin && date_range.end < end_time)

        Recurrence::Occurrence.new(starts_at: start_time, ends_at: end_time)
      end.to_a
    end

    def next_future_event
      events(params: { starts: @model.starts_at, until: @model.recurrence_ends_at }).each do |event|
        break event if event.future?
      end
    end

    private

    def update_rules(params = {})
      @schedule.rules.map { |rule| rule.merge(params) }
    end

    def schedule_options
      weekly_multiple_recurrence? ? active_days.map { |day| day_options(day) } : [default_options]
    end

    def day_options(day)
      default_options.merge(on: [day], at: @model.recurrence["#{day}_start_time"])
    end

    def parse_date(date)
      return nil if date.to_s.starts_with?("__/")

      date.to_s.to_date
    end

    def parse_int(value)
      return nil if value.blank?

      value.to_i
    end

    def parse_collection(value)
      return nil if value.blank?

      value.compact_blank
    end

    def weekly_multiple_recurrence?
      @model.recurrence_type == "multiple" && @model.every == "week"
    end

    def active_days
      parse_collection(@model.recurrence[:on])
    end

    def end_time_for(start_time)
      duration = if weekly_multiple_recurrence?
                   day = start_time.strftime("%A").downcase
                   Time.zone.parse(@model.recurrence["#{day}_end_time"]) - Time.zone.parse(@model.recurrence["#{day}_start_time"])
                 else
                   @model.duration
                 end

      start_time + duration
    end

    def events(params: {})
      Montrose::Schedule.new(update_rules(params)).events.lazy
    end
  end
end
