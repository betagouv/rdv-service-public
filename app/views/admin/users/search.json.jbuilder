# frozen_string_literal: true

json.results @users do |user|
  json.id user.id
  json.text reverse_full_name_and_birthdate(user)
end
