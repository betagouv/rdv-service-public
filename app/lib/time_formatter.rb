module TimeFormatter
  def self.french_time(datetime)
    datetime.strftime("%kh%M").strip.gsub("00", "")
  end

  def self.french_time_range(start_time, end_time)
    [french_time(start_time), french_time(end_time)].join(" à ")
  end
end
