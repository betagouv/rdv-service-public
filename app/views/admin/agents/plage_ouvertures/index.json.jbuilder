# frozen_string_literal: true

json.array! @plage_ouverture_occurrences do |plage_ouverture, occurrence|
  json.title plage_ouverture.title
  json.start occurrence.starts_at.as_json
  json.end occurrence.ends_at.as_json

  if plage_ouverture.organisation == @organisation
    json.backgroundColor "#6fceff80"
    json.textColor "black"
  else
    json.backgroundColor "grey"
  end
  json.display "background"
  json.url new_admin_organisation_rdv_wizard_step_path(plage_ouverture.organisation)

  json.editable false
  json.extendedProps do
    json.organisationName plage_ouverture.organisation.name
    json.location plage_ouverture.lieu.address
    json.lieu plage_ouverture.lieu.name
  end
end
