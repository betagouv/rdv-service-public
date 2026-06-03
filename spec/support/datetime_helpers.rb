def today_at(hour, min = 0)
  Time.zone.now.change(hour:, min:)
end

def tomorrow_at(hour)
  Time.zone.tomorrow.to_time.change(hour:)
end
