# frozen_string_literal: true

json.array! @plage_ouverture_occurrences do |plage_ouverture, occurrence|
  json.title plage_ouverture.title
  json.start occurrence.starts_at.as_json
  json.end occurrence.ends_at.as_json
  if plage_ouverture.organisation == @organisation
    json.backgroundColor "#6fceff80"
  else
    json.backgroundColor "grey"
  end
  json.rendering "background"
  json.extendedProps do
    json.organisationName plage_ouverture.organisation.name
    if plage_ouverture.lieu
      json.location plage_ouverture.lieu.address
    end
    json.lieu plage_ouverture.lieu&.name || "pas de lieu"
  end
end
