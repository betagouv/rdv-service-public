json.start unauthorized_rdv.starts_at.as_json
json.end unauthorized_rdv.ends_at.as_json

json.title "Occupé⋅e (en RDV)"
json.textColor "black"
json.backgroundColor "#dadada" # Overridden by striped background in CSS
json.extendedProps do
  json.unauthorizedRdvExplanation "Vous ne pouvez pas voir ce RDV parce qu'il a lieu dans un autre service ou une autre organisation"
end
