json.cache! [@plage_ouverture_occurrences, :all_occurrences_for, date_range_params, @organisation.id], expires_in: 8.hours do
  json.array! @plage_ouverture_occurrences do |plage_ouverture, occurrence|
    json.title plage_ouverture.title
    json.start occurrence.starts_at.as_json
    json.end occurrence.ends_at.as_json
    if plage_ouverture.organisation == @organisation
      json.backgroundColor "#6fceff80"
    else
      json.backgroundColor "grey"
    end
    json.textColor "#313131"
    json.rendering "background" if params[:in_background]

    json.url admin_organisation_plage_ouverture_path(@organisation, plage_ouverture)
    json.extendedProps do
      json.organisationName plage_ouverture.organisation.name
      json.location plage_ouverture.lieu_address
      json.lieu plage_ouverture.lieu_name
    end
  end
end
