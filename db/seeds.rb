# TODO: when trying to create models using direct associations like
# `organisation: org1` instead of `organisation_id: org1.id`
# CircleCI throws ActiveRecord::AssociationTypeMismatch that seems to indicate
# that the model files are loaded twice, or something related to HABTM
# associations..

# ORGANISATIONS

org1 = Organisation.create!(name: "MDS du 75", phone_number: "0123456789", departement: "75")
org2 = Organisation.create!(name: "MDS du 62", phone_number: "0123456789", departement: "62")

# SERVICES

service_pmi = Service.create!(name: "Protection Maternelle Infantile", short_name: "PMI")
service_social = Service.create!(name: "Service Social", short_name: "Service Social")
_service_secretariat = Service.create!(name: "Secrétariat", short_name: "Secrétariat")
_service_ehpad = Service.create!(name: "EHPAD", short_name: "EHPAD")

# SERVICE LIBELLES

libelle_pmi_rappel = MotifLibelle.create!(service: service_pmi, name: "Être rappelé par la PMI")
libelle_pmi_prenatale = MotifLibelle.create!(service: service_pmi, name: "Consultation prénatale")
libelle_pmi_suivi = MotifLibelle.create!(service: service_pmi, name: "Suivi après naissance")
libelle_pmi_securite = MotifLibelle.create!(service: service_pmi, name: "Sécurité du domicile")
libelle_social_rappel = MotifLibelle.create!(service: service_social, name: "Être rappelé par la MDS")
libelle_social_suivi = MotifLibelle.create!(service: service_social, name: "Suivi RSA")
libelle_social_droits = MotifLibelle.create!(service: service_social, name: "Droits sociaux")

# MOTIFS ORG1

motif_org1_pmi_rappel = Motif.create!(
  name: libelle_pmi_rappel.name,
  color: '#FF7C00',
  organisation_id: org1.id,
  service_id: service_pmi.id,
  reservable_online: true,
  location_type: :phone
)
motif_org1_pmi_prenatale = Motif.create!(
  name: libelle_pmi_prenatale.name,
  color: '#CC7C00',
  organisation_id: org1.id,
  service_id: service_pmi.id,
  reservable_online: true,
  location_type: :public_office
)
motif_org1_pmi_suivi = Motif.create!(
  name: libelle_pmi_suivi.name,
  color: '#00FC60',
  organisation_id: org1.id,
  service_id: service_pmi.id,
  reservable_online: true,
  location_type: :public_office,
  follow_up: true
)
motif_org1_pmi_securite = Motif.create!(
  name: libelle_pmi_securite.name,
  color: '#1010FF',
  organisation_id: org1.id,
  service_id: service_pmi.id,
  reservable_online: true,
  location_type: :home
)
_motif_org1_social_rappel = Motif.create!(
  name: libelle_social_rappel.name,
  color: '#FF7C00',
  organisation_id: org1.id,
  service_id: service_social.id,
  reservable_online: true,
  location_type: :phone
)
_motif_org1_social_suivi = Motif.create!(
  name: libelle_social_suivi.name,
  color: '#CC7C00',
  organisation_id: org1.id,
  service_id: service_social.id,
  reservable_online: true,
  location_type: :public_office,
  follow_up: true
)
_motif_org1_social_droits = Motif.create!(
  name: libelle_social_droits.name,
  color: '#00FC60',
  organisation_id: org1.id,
  service_id: service_social.id,
  reservable_online: true,
  location_type: :public_office
)

# MOTIFS ORG2

motif_org2_pmi_rappel = Motif.create!(
  name: libelle_pmi_rappel.name,
  color: '#10FF10',
  organisation_id: org2.id,
  service_id: service_pmi.id,
  reservable_online: true,
  location_type: :phone
)
motif_org2_pmi_prenatale = Motif.create!(
  name: libelle_pmi_prenatale.name,
  color: '#FF1010',
  organisation_id: org2.id,
  service_id: service_pmi.id,
  reservable_online: true,
  location_type: :public_office
)

# LIEUX

lieu_org1_sud = Lieu.create!(
  name: "Maison Paris Sud",
  organisation: org1,
  address: "18 Rue des Terres au Curé, 75013 Paris",
  latitude: 48.85295,
  longitude: 2.34998
)
lieu_org1_nord = Lieu.create!(
  name: "Maison Paris Nord",
  organisation: org1,
  address: "18 Boulevard d'Aubervilliers, 75019 Paris",
  latitude: 48.8882196,
  longitude: 2.3650464
)
lieu_org2_nord = Lieu.create!(
  name: "Maison Calais Nord",
  organisation: org2,
  address: "53 Rue Mouron, 62100 Calais",
  latitude: 50.9616184,
  longitude: 1.8693743
)

# USERS

user_org1_patricia = User.new(
  first_name: "Patricia",
  last_name: "Duroy",
  email: "patricia_duroy@demo.rdv-solidarites.fr",
  birth_date: Date.parse("20/06/1975"),
  password: '123456',
  organisation_ids: [org1.id]
)
user_org1_patricia.skip_confirmation!
user_org1_patricia.save!

user_org1_lea = User.new(
  first_name: "Léa",
  last_name: "Dupont",
  email: "lea_dupont@demo.rdv-solidarites.fr",
  birth_date: Date.parse("01/12/1982"),
  password: '123456',
  organisation_ids: [org1.id]
)
user_org1_lea.skip_confirmation!
user_org1_lea.save!

user_org1_jean = User.new(
  first_name: "Jean",
  last_name: "Moustache",
  email: "jean_moustache@demo.rdv-solidarites.fr",
  birth_date: Date.parse("10/01/1973"),
  password: '123456',
  organisation_ids: [org1.id]
)
user_org1_jean.skip_confirmation!
user_org1_jean.save!

# AGENTS

agent_org1_pmi_martine = Agent.new(
  email: 'martine@demo.rdv-solidarites.fr',
  role: :admin,
  first_name: 'Martine',
  last_name: 'Validay',
  password: '123456',
  service_id: service_pmi.id,
  organisation_ids: [org1.id]
)
agent_org1_pmi_martine.skip_confirmation!
agent_org1_pmi_martine.save!

agent_org1_pmi_marco = Agent.new(
  email: 'marco@demo.rdv-solidarites.fr',
  role: :user,
  first_name: 'Marco',
  last_name: 'Durand',
  password: '123456',
  service_id: service_pmi.id,
  organisation_ids: [org1.id]
)
agent_org1_pmi_marco.skip_confirmation!
agent_org1_pmi_marco.save!

agent_org2_pmi_maya = Agent.new(
  email: 'maya@demo.rdv-solidarites.fr',
  role: :admin,
  first_name: 'Maya',
  last_name: 'Patrick',
  password: '123456',
  service_id: service_pmi.id,
  organisation_ids: [org2.id]
)
agent_org2_pmi_maya.skip_confirmation!
agent_org2_pmi_maya.save!

# PLAGES OUVERTURES

PlageOuverture.skip_callback(:create, :after, :plage_ouverture_created)
_plage_ouverture_org1_martine_classique = PlageOuverture.create!(
  title: 'Permanence classique',
  organisation_id: org1.id,
  agent_id: agent_org1_pmi_martine.id,
  lieu_id: lieu_org1_sud.id,
  motif_ids: [motif_org1_pmi_rappel.id, motif_org1_pmi_prenatale.id, motif_org1_pmi_suivi.id, motif_org1_pmi_securite.id],
  first_day: Date.tomorrow,
  start_time: Tod::TimeOfDay.new(8),
  end_time: Tod::TimeOfDay.new(18),
  recurrence: Montrose.every(:day)
)
_plage_ouverture_org1_marco_perm = PlageOuverture.create!(
  title: 'Perm.',
  organisation_id: org1.id,
  agent_id: agent_org1_pmi_marco.id,
  lieu_id: lieu_org1_nord.id,
  motif_ids: [motif_org1_pmi_rappel.id, motif_org1_pmi_prenatale.id, motif_org1_pmi_suivi.id, motif_org1_pmi_securite.id],
  first_day: Date.tomorrow,
  start_time: Tod::TimeOfDay.new(8),
  end_time: Tod::TimeOfDay.new(12),
  recurrence: Montrose.every(:day)
)
_plage_ouverture_org2_maya_tradi = PlageOuverture.create!(
  title: 'Perm. tradi',
  organisation_id: org2.id,
  agent_id: agent_org2_pmi_maya.id,
  lieu_id: lieu_org2_nord.id,
  motif_ids: [motif_org2_pmi_rappel.id, motif_org2_pmi_prenatale.id],
  first_day: Date.tomorrow,
  start_time: Tod::TimeOfDay.new(9),
  end_time: Tod::TimeOfDay.new(15),
  recurrence: Montrose.every(:day)
)
PlageOuverture.set_callback(:create, :after, :plage_ouverture_created)

# RDVs

Rdv.skip_callback(:create, :after, :notify_rdv_created)
rdv1 = Rdv.new(
  duration_in_min: 30,
  starts_at: Date.today + 3.days + 10.hours,
  motif_id: motif_org1_pmi_rappel.id,
  lieu: lieu_org1_sud,
  organisation_id: org1.id,
  agent_ids: [agent_org1_pmi_martine.id],
  user_ids: [user_org1_patricia.id],
  notes: "Rendez-vous important !"
)
rdv1.save!
Rdv.set_callback(:create, :after, :notify_rdv_created)
