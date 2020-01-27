json.array! @jours_feries do |jour_ferie|
  json.title "Jour férié"
  json.start jour_ferie.beginning_of_day
  json.end jour_ferie.end_of_day
  json.backgroundColor "#95a5a6"
end
