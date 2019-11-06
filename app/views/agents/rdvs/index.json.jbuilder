json.array! @rdvs do |rdv|
  json.title rdv.name
  json.extendedProps do
    json.status rdv.status
    json.past rdv.past?
  end
  json.start rdv.starts_at
  json.end rdv.ends_at
  json.url organisation_rdv_path(rdv.organisation, rdv)
  json.backgroundColor rdv.motif&.color
end
