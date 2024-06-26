module Lapin
  class Schedule
    InvalidRecurrenceData = Class.new(StandardError)

    delegate :lazy, :include, :default_options, to: :schedule

    def initialize(model)
      raise InvalidRecurrenceData if model.every.blank?

      @model = model
      @schedule = Montrose::Schedule.new(schedule_options)
    end

    def events(params = {})
      Montrose::Schedule.new(update_rules(params)).events.lazy
    end

    def to_h
      @schedule.rules.first.to_h
    end

    private

    def update_rules(params = {})
      @schedule.rules.map { |rule| rule.merge(params) }
    end

    def schedule_options
      weekly_multiple_recurrence? ? active_days.map { |day| day_options(day) } : [default_options]
    end

    def day_options(day)
      default_options.merge(
        on: [day],
        hour: @model.recurrence["#{day}_start_time"].to_i..@model.recurrence["#{day}_end_time"].to_i
      )
    end

    def default_options
      @default_options ||= {
        every: @model.recurrence[:every],
        interval: parse_int(@model.recurrence[:interval]),
        total: parse_int(@model.recurrence[:total]),
        on: active_days,
        starts: @model.first_day,
        until: parse_date(@model.recurrence[:until]),
        ends: parse_date(@model.recurrence[:ends]),
        day: parse_collection(@model.recurrence[:day]),
      }.compact_blank
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
  end
end
