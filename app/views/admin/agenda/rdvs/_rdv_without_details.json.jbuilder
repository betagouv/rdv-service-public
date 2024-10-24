json.start rdv_without_details.starts_at.as_json
json.end rdv_without_details.ends_at.as_json

json.title "Occupé⋅e (en RDV)"
json.textColor "white"
json.backgroundColor "#757575" # Use a dark enough gray to be accessible
json.extendedProps do
  json.unauthorizedRdvExplanation "Vous ne pouvez pas voir ce RDV parce qu'il a lieu dans un autre service ou une autre organisation"
end
