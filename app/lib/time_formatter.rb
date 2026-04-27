module TimeFormatter
  def self.french_time(datetime)
    minutes = datetime.min.zero? ? nil : datetime.min
    minute_zero_padding = datetime.min.in?(1..9) ? "0" : ""
    "#{datetime.hour}h#{minute_zero_padding}#{minutes}"
  end

  def self.french_time_range(start_time, end_time)
    [french_time(start_time), french_time(end_time)].join("-")
  end
end
