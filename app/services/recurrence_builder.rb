class RecurrenceBuilder
  def self.create(model)
    new(model).create
  end

  def initialize(model)
    @model = model
  end

  def create
    return nil if @model.recurrence[:every].blank?

    Montrose::Recurrence.new(parse_options(@model.recurrence))
  end

  private

  def parse_options(options)
    options = options.slice(:every, :total, :interval, :on, :until, :starts, :ends, :day)
    options[:total] = parse_int(options[:total])
    options[:interval] = parse_int(options[:interval])
    options[:on] = parse_collection(options[:on])
    options[:until] = parse_date(options[:until])
    options[:starts] = parse_date(options[:starts] || @model.first_day)
    options[:ends] = parse_date(options[:ends])
    options[:day] = parse_collection(options[:day])
    if options[:every] == :month
      options[:day] ||= { @model.first_day.cwday => [week_day_position_in_month] }
    end

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

  def week_day_position_in_month
    (@model.first_day.day - 1).div(7) + 1
  end
end
