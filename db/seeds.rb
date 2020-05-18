# TODO: when trying to create models using direct associations like
# `organisation: org1` instead of `organisation_id: org1.id`
# CircleCI throws ActiveRecord::AssociationTypeMismatch that seems to indicate
# that the model files are loaded twice, or something related to HABTM
# associations..

org1 = Organisation.create!(name: "MDS du 75", phone_number: "0123456789", departement: "75")

service1 = Service.create!(name: "Protection Maternelle Infantile", short_name: "PMI")
_service2 = Service.create!(name: "Service Social", short_name: "Service Social")
Service.create!(name: "Secrétariat", short_name: "Secrétariat")
Service.create!(name: "EHPAD", short_name: "EHPAD")

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
  organisation_id: org1.id,
  service_id: service1.id,
  online: true
)

user1 = User.new(
  first_name: "Patricia",
  last_name: "Duroy",
  email: "patricia_duroy@demo.rdv-solidarites.fr",
  birth_date: Date.parse("20/06/1975"),
  password: '123456',
  organisation_ids: [org1.id]
)
user1.skip_confirmation!
user1.save!

user2 = User.new(
  first_name: "Léa",
  last_name: "Dupont",
  email: "martine_dupont@demo.rdv-solidarites.fr",
  birth_date: Date.parse("01/12/1982"),
  password: '123456',
  organisation_ids: [org1.id]
)
user2.skip_confirmation!
user2.save!

user3 = User.new(
  first_name: "Jean",
  last_name: "Moustache",
  email: "jean_moustache@demo.rdv-solidarites.fr",
  birth_date: Date.parse("10/01/1973"),
  password: '123456',
  organisation_ids: [org1.id]
)
user3.skip_confirmation!
user3.save!

agent1 = Agent.new(
  email: 'martine@demo.rdv-solidarites.fr',
  role: 1, # == admin
  first_name: 'Martine',
  last_name: 'Validay',
  password: '123456',
  service_id: service1.id,
  organisation_ids: [org1.id]
)
agent1.skip_confirmation!
agent1.save!

agent2 = Agent.new(
  email: 'marco@demo.rdv-solidarites.fr',
  role: :user,
  first_name: 'Marco',
  last_name: 'Durand',
  password: '123456',
  service_id: service1.id,
  organisation_ids: [org1.id]
)
agent2.skip_confirmation!
agent2.save!

_plage_ouverture1 = PlageOuverture.create!(
  title: 'Permanence classique',
  organisation_id: org1.id,
  agent_id: agent1.id,
  lieu_id: lieu1.id,
  motif_ids: [motif1.id],
  first_day: Date.tomorrow,
  start_time: Tod::TimeOfDay.new(8),
  end_time: Tod::TimeOfDay.new(12),
  recurrence: Montrose.every(:day)
)

rdv1 = Rdv.new(
  duration_in_min: 30,
  starts_at: Date.today + 3.days + 10.hours,
  motif_id: motif1.id,
  location: lieu1.address,
  organisation_id: org1.id,
  agent_ids: [agent1.id],
  user_ids: [user1.id],
  notes: "Rendez-vous important !"
)
rdv1.save!
