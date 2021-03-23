json.array! @absence_occurrences do |absence, occurrence|
  json.title absence.title_or_default
  json.start occurrence.starts_at
  json.end occurrence.ends_at
  json.backgroundColor "#7f8c8d"
  json.url edit_admin_organisation_absence_path(absence.organisation, absence)
end
