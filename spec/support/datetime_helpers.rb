def today_at(hour, min = 0)
  Time.zone.now.change(hour:, min:)
end

def tomorrow_at(hour)
  1.day.from_now.change(hour:)
end
