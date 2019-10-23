json.array! @absences do |absence|
  json.title absence.title_or_default
  json.start absence.starts_at
  json.end absence.ends_at
  json.backgroundColor "#7f8c8d"
  json.url edit_absence_path(absence)
end
