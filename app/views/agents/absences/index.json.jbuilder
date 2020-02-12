json.array! @absence_ocurrences do |absence, occurence|
  json.title absence.title_or_default
  json.start occurence
  json.end absence.end_time.on(occurence + (absence.end_day - absence.first_day).to_i.days)
  json.backgroundColor "#7f8c8d"
  json.url edit_organisation_absence_path(absence.organisation, absence)
end
