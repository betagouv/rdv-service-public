json.array! @plage_ouverture_occurences do |plage_ouverture, occurence|
  json.title plage_ouverture.title
  json.start occurence.starts_at
  json.end occurence.ends_at
  json.backgroundColor "#F00"
  json.rendering "background"
  json.extendedProps do
    json.location plage_ouverture.lieu.address
    json.lieu plage_ouverture.lieu.name
  end
end
