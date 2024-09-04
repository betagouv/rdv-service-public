json.cache! [@absence_occurrences, :all_occurrences_for, date_range_params, @organisation.id], expires_in: 8.hours do
  json.array! @absence_occurrences do |absence, occurrence|
    json.title absence.title
    json.start occurrence.starts_at.as_json
    json.end occurrence.ends_at.as_json
    json.backgroundColor "rgba(127, 140, 141, 0.7)"

    # url pour modifier l'absence
    json.url edit_admin_organisation_absence_path(@organisation, absence)
  end
end
