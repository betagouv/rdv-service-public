Organisation.create!(name: "MDS du 75", phone_number: "0123456789", departement: "75")

Service.create!(name: "Protection Maternelle Infantile", short_name: "PMI")
Service.create!(name: "Service Social", short_name: "Service Social")

Lieu.create!(name: "Maison Paris Sud", organisation_id: 1, address: "18 Rue des Terres au Curé, 75013 Paris", latitude: 48.85295, longitude: 2.34998)

Motif.create!(name: 'Consultation médicale', color: '#FF7C00', organisation_id: 1, service_id: 1)

3.times do |_u|
  User.create!(first_name: Faker::Name.first_name, last_name: Faker::Name.last_name, email: Faker::Internet.email, birth_date: Faker::Date.birthday, password: Faker::Internet.password, organisation_ids: [1])
end

Agent.create!(email: 'contact@rdv-solidarites.fr', role: 1, first_name: 'Johnny', last_name: 'Validay', password: '123456', service_id: 1, organisation_ids: [1])
