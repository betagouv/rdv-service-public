class RecurrenceBuilder
  def self.build(model)
    new(model).build
  end

  def initialize(model)
    @model = model
  end

  def build
    return nil if @model.every.blank?

    weekly_multiple_recurrence? ? build_schedule : build_recurrence
  end

  private

  def build_schedule
    schedule = Montrose::Schedule.new
    days = @model.recurrence[:on].compact_blank
    days.each do |day|
      schedule << params_for_day_recurrence(day)
    end

    schedule
  end

  def build_recurrence
    Montrose::Recurrence.new(parse_options(@model.recurrence))
  end

  def params_for_day_recurrence(day)
    options = parse_options(@model.recurrence)
    options[:on] = [day]
    options[:during] = [@model.recurrence.fetch("#{day}_start_time"), @model.recurrence.fetch("#{day}_end_time")].join("-")

    options
  end

  def parse_options(options)
    options = options.slice(:every, :total, :interval, :on, :until, :starts, :ends, :day)
    options[:interval] = parse_int(options[:interval])
    options[:total] = parse_int(options[:total])
    options[:on] = parse_collection(options[:on])
    options[:until] = parse_date(options[:until])
    options[:starts] = parse_date(options[:starts] || @model.first_day)
    options[:ends] = parse_date(options[:ends])
    options[:day] = parse_collection(options[:day])

    options.compact_blank!
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
end
