# frozen_string_literal: true

json.cache! [@absence_occurrences, :all_occurrences_for, date_range_params], expires_in: 8.hours do
  json.array! @absence_occurrences do |absence, occurrence|
    json.title absence.title
    json.start occurrence.starts_at.as_json
    json.end occurrence.ends_at.as_json
    json.backgroundColor "rgba(127, 140, 141, 0.7)"

    # url pour éditer l'absence
    # TODO trouver un meilleur nom à cet attribut pour en plus avoir besoin de ce commentaire
    json.url edit_admin_organisation_absence_path(absence.organisation, absence) if absence.organisation == @organisation

    json.extendedProps do
      json.organisationName absence.organisation.name
    end
  end
end
