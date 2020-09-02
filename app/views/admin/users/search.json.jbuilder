json.results @users do |user|
  json.id user.id
  json.text full_name_and_birthdate(user)
end
