# rails runner scripts/copy_users_between_orgas.rb

origin_organisation_ids = [
  86, # MDSI Albert
  87, # MDSI Corbie
  88 # MDSI Peronne
]

target_organisation = Organisation.find(85) # TERRITOIRE HAUTS DE SOMME

users = User.joins(:organisations).where(organisations: { id: origin_organisation_ids })
puts "copying #{users.count} users from origin to target..."
users.find_each { _1.add_organisation(target_organisation) }
puts "done!"
