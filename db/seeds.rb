org1 = Organisation.create!(name: "MDS du 75", phone_number: "0123456789", departement: "75")

service1 = Service.create!(name: "Protection Maternelle Infantile", short_name: "PMI")
_service2 = Service.create!(name: "Service Social", short_name: "Service Social")

lieu1 = Lieu.create!(
  name: "Maison Paris Sud",
  organisation: org1,
  address: "18 Rue des Terres au Curé, 75013 Paris",
  latitude: 48.85295,
  longitude: 2.34998
)

motif1 = Motif.create!(
  name: 'Consultation médicale',
  color: '#FF7C00',
  organisation: org1,
  service: service1,
  online: true
)

3.times do |_u|
  User.create!(
    first_name: Faker::Name.first_name,
    last_name: Faker::Name.last_name,
    email: Faker::Internet.email,
    birth_date: Faker::Date.birthday,
    password: '123456',
    organisation_ids: [org1.id]
  )
end

agent1 = Agent.create!(
  email: 'contact@rdv-solidarites.fr',
  role: 1, # == admin
  first_name: 'Johnny',
  last_name: 'Validay',
  password: '123456',
  service: service1,
  organisation_ids: [org1.id]
)

_plage_ouverture1 = PlageOuverture.create!(
  title: 'Permanence classique',
  organisation: org1,
  agent: agent1,
  lieu: lieu1,
  motifs: [motif1],
  first_day: Date.tomorrow,
  start_time: Tod::TimeOfDay.new(8),
  end_time: Tod::TimeOfDay.new(12),
  recurrence: Montrose.every(:day)
)
