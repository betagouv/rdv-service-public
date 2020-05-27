json.array! @plage_ouverture_occurences do |plage_ouverture, occurence|
  json.title plage_ouverture.title
  json.start occurence.starts_at
  json.end occurence.ends_at
  json.backgroundColor "#6fceff80"
  json.rendering "background"
  json.extendedProps do
    json.location plage_ouverture.lieu.address
    json.lieu plage_ouverture.lieu.name
  end
end
l organisation_rdv_path(rdv.organisation, rdv)
  json.backgroundColor rdv.motif&.color
end
