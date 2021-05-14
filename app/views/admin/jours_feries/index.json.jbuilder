# frozen_string_literal: true

json.array! @jours_feries do |jour_ferie|
  json.title "Jour férié 🎉"
  json.start jour_ferie.beginning_of_day
  json.end jour_ferie.end_of_day
  json.backgroundColor "#cecece"
  json.allDay true
  json.extendedProps do
    json.jour_feries true
  end
end
