# Territories
territory_val_doise = Territory.create!(
  departement_number: "95",
  name: "Val D'oise",
  sms_provider: "netsize",
  sms_configuration: "login:pwd"
)

# Organisations
org_mairie_de_sannois = Organisation.create!(
  name: "Mairie de Sannois",
  phone_number: "0475796991",
  territory: territory_val_doise,
  verticale: :rdv_mairie
)

# Service
service_titres = Service.create!(name: "Service Titres Sécurisés", short_name: "STS")

territory_val_doise.services << service_titres

MotifCategory.create!(name: "Carte d'identité disponible sur le site de l'ANTS", short_name: "CNI")
MotifCategory.create!(name: "Passeport disponible sur le site de l'ANTS", short_name: "PASSPORT")
MotifCategory.create!(name: "Carte d'identité et passeport disponible sur le site de l'ANTS", short_name: "CNI-PASSPORT")

# MOTIFS
motif_passeport = Motif.create!(
  name: "Passeport",
  color: "#00ffff",
  motif_category: MotifCategory.find_by!(short_name: "PASSPORT"),
  default_duration_in_min: 30,
  organisation: org_mairie_de_sannois,
  bookable_by: :everyone,
  max_public_booking_delay: 2_629_746,
  service: service_titres,
  for_secretariat: true
)

# Agent
agent_mairie_de_sannois = Agent.new(
  email: "alain.mairie@rdv-mairie-demo.fr",
  uid: "alain.mairie@rdv-mairie-demo.fr",
  first_name: "Alain",
  last_name: "Mairie",
  password: "Rdvservicepublictest1!",
  services: [service_titres],
  invitation_accepted_at: 10.days.ago,
  roles_attributes: [
    { organisation: org_mairie_de_sannois, access_level: AgentRole::ACCESS_LEVEL_ADMIN },
  ],
  agent_territorial_access_rights_attributes: [
    { territory: territory_val_doise, allow_to_manage_teams: true },
  ]
)
agent_mairie_de_sannois.skip_confirmation!
agent_mairie_de_sannois.save!
agent_mairie_de_sannois.territorial_roles.create!(territory: territory_val_doise)

## Lieux
lieu_mairie_de_sannois = Lieu.create!(
  name: "Mairie de Sannois",
  organisation: org_mairie_de_sannois,
  latitude: 44.733748,
  longitude: 5.004262,
  availability: :enabled,
  phone_number: "04.75.79.69.91",
  phone_number_formatted: "+33475796991",
  address: "15 Place du Général Leclerc, Sannois, 26400"
)

## Plages d'Ouvertures

_plage_ouverture_org_drome_lieu_mairie_de_sannois = PlageOuverture.create!(
  title: "Permanence classique",
  organisation_id: org_mairie_de_sannois.id,
  agent_id: agent_mairie_de_sannois.id,
  lieu_id: lieu_mairie_de_sannois.id,
  motif_ids: [motif_passeport.id],
  first_day: Date.tomorrow,
  start_time: Tod::TimeOfDay.new(8),
  end_time: Tod::TimeOfDay.new(12),
  recurrence: Montrose.every(:week, day: [1, 2, 3, 4, 5], interval: 1, starts: Date.tomorrow, on: %i[monday tuesday thursday friday])
)
