# frozen_string_literal: true

json.array! @jours_feries do |jour_ferie|
  json.title "Jour férié 🎉"
  json.start jour_ferie.beginning_of_day.as_json
  json.end jour_ferie.end_of_day.as_json
  json.backgroundColor "#cecece"
  json.allDay true
  json.extendedProps do
    json.jour_feries true
  end
end
