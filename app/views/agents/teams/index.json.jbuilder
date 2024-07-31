json.results @teams do |team|
  json.id team.id
  json.text team.name
end
