def date_and_time(date, time)
  Tod::TimeOfDay.parse(time).on(date)
end

def today_at(time)
  Tod::TimeOfDay.parse(time).on(Time.zone.today)
end

def tomorrow_at(time)
  Tod::TimeOfDay.parse(time).on(Time.zone.tomorrow)
end
