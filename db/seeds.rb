# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rails db:seed command (or created alongside the database with db:setup).
#
# Examples:
#
#   movies = Movie.create([{ name: 'Star Wars' }, { name: 'Lord of the Rings' }])
#   Character.create(name: 'Luke', movie: movies.first)

Organisation.create!(name: "MDS du 75", departement: "59")

Lieu.create!(name: "Maison Gare du Nord", telephone: "0123456789", organisation_id: 1, address: "1 rue de Maubeuge, 75009 Paris", horaires: "Du lundi au vendredi de 9h à 18h")

100.times do |_u|
  User.create!(first_name: Faker::Name.first_name, last_name: Faker::Name.last_name, email: Faker::Internet.email, birth_date: Faker::Date.birthday, password: Faker::Internet.password, organisation_ids: [1])
end

Service.create!(name: "Protection Maternelle Infantile")
Service.create!(name: "Service Social")
