json.results @users do |user|
  json.id user.id
  json.text reverse_full_name_and_birthdate(user)
  break_specs
end
