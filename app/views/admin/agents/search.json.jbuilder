# frozen_string_literal: true

json.results @agents do |agent|
  json.id agent.id
  json.text agent.reverse_full_name
end
