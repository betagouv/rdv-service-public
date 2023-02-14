# frozen_string_literal: true

# En effet, on rencontre ce problème : Casecommons/pg_search#238
# Le uniq est un solution qui casse parfois le décompte, mais ça paraît acceptable !
json.results @users.uniq do |user|
  json.id user.id
  json.text reverse_full_name_and_birthdate(user)
end
