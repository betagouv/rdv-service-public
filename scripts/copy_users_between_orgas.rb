# rails runner scripts/copy_users_between_orgas.rb

origin_organisation_ids = [
  148, # MDSI Moreuil
  147, # MDSI Eppeville
  146, # MDSI Roye
  145, # MDSI Montdidier
  144, # MDSI Chaulnes
]

target_organisation = Organisation.find(149) # TERRITOIRE SOMME-SANTERRE

users = User.joins(:organisations).where(organisations: { id: origin_organisation_ids })
puts "copying #{users.count} users from origin to target..."
users.find_each { _1.add_organisation(target_organisation) }
puts "done!"
