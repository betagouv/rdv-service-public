json.array! @plage_ouverture_occurrences do |plage_ouverture, occurrence|
  json.title plage_ouverture.title
  json.start occurrence.starts_at
  json.end occurrence.ends_at
  if plage_ouverture.organisation == @organisation
    json.backgroundColor "#6fceff80"
  else
    json.backgroundColor "grey"
  end
  json.rendering "background"
  json.extendedProps do
    json.location plage_ouverture.lieu.address
    json.lieu plage_ouverture.lieu.name
  end
end
