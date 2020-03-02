json.array! @absence_occurrences do |absence, occurence|
  json.title absence.title_or_default
  json.start occurence.starts_at
  json.end occurence.ends_at
  json.backgroundColor "#7f8c8d"
  json.url edit_organisation_absence_path(absence.organisation, absence)
end
