def tomorrow_at(hour)
  Time.zone.tomorrow.at(Tod::TimeOfDay(hour))
end
