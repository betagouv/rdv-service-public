json.array! @rdvs do |rdv|
  # peut appeler les partials "_rdv" ou "_rdv_without_details" selon la classe de `rdv`
  json.partial! rdv
end
