json.results @agents do |agent|
  json.id agent.id
  json.text agent.reverse_full_name_or_email
end
