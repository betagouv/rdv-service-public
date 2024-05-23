# Territories
territory_gironde = Territory.create!(
  departement_number: "33",
  name: "Gironde",
  sms_provider: "netsize",
  sms_configuration: "login:pwd"
)

# Organisations
org_cdad1 = Organisation.create!(
  name: "CDAD 1",
  phone_number: "0475796991",
  territory: territory_gironde,
  verticale: :rdv_solidarites
)
org_cdad2 = Organisation.create!(
  name: "CDAD 2",
  phone_number: "0475796992",
  territory: territory_gironde,
  verticale: :rdv_solidarites
)

# Service
service_cdad = Service.create!(name: "CDAD (Conseils Départementaux de l’Accès au Droit)", short_name: "CDAD")
territory_gironde.services << service_cdad

# Motifs
motif1_cdad1 = Motif.create!(
  name: "RDV Avocat",
  color: "#00ffff",
  default_duration_in_min: 60,
  organisation: org_cdad1,
  bookable_by: "agents",
  max_public_booking_delay: 2_629_746,
  service: service_cdad,
  for_secretariat: true
)

# Agent
all_cdad_agent = Agent.new(
  email: "secretariat@cdad.fr",
  uid: "secretariat@cdad.fr",
  first_name: "Maxime",
  last_name: "Secrétariat",
  password: "Rdvservicepublictest1!",
  services: [service_cdad],
  invitation_accepted_at: 10.days.ago,
  roles_attributes: [
    { organisation: org_cdad1, access_level: AgentRole::ACCESS_LEVEL_ADMIN },
    { organisation: org_cdad2, access_level: AgentRole::ACCESS_LEVEL_ADMIN },
  ],
  agent_territorial_access_rights_attributes: [
    { territory: territory_gironde, allow_to_manage_teams: true },
  ]
)
all_cdad_agent.skip_confirmation!
all_cdad_agent.save!
all_cdad_agent.territorial_roles.create!(territory: territory_gironde)

cdad1_agent = Agent.new(
  email: "cdad1@cdad.fr",
  uid: "cdad1@cdad.fr",
  first_name: "Basic",
  last_name: "CDAD1",
  password: "Rdvservicepublictest1!",
  services: [service_cdad],
  invitation_accepted_at: 10.days.ago,
  roles_attributes: [
    { organisation: org_cdad1, access_level: AgentRole::ACCESS_LEVEL_BASIC },
  ],
  agent_territorial_access_rights_attributes: [
    { territory: territory_gironde, allow_to_manage_teams: true },
  ]
)
cdad1_agent.skip_confirmation!
cdad1_agent.save!
cdad1_agent.territorial_roles.create!(territory: territory_gironde)

cdad1_admin = Agent.new(
  email: "cdad1_admin@cdad.fr",
  uid: "cdad1_admin@cdad.fr",
  first_name: "Admin",
  last_name: "CDAD1",
  password: "Rdvservicepublictest1!",
  services: [service_cdad],
  invitation_accepted_at: 10.days.ago,
  roles_attributes: [
    { organisation: org_cdad1, access_level: AgentRole::ACCESS_LEVEL_ADMIN },
  ],
  agent_territorial_access_rights_attributes: [
    { territory: territory_gironde, allow_to_manage_teams: true },
  ]
)
cdad1_admin.skip_confirmation!
cdad1_admin.save!
cdad1_admin.territorial_roles.create!(territory: territory_gironde)

cdad2_agent = Agent.new(
  email: "cdad2@cdad.fr",
  uid: "cdad2@cdad.fr",
  first_name: "Basic",
  last_name: "CDAD2",
  password: "Rdvservicepublictest1!",
  services: [service_cdad],
  invitation_accepted_at: 10.days.ago,
  roles_attributes: [
    { organisation: org_cdad2, access_level: AgentRole::ACCESS_LEVEL_BASIC },
  ],
  agent_territorial_access_rights_attributes: [
    { territory: territory_gironde, allow_to_manage_teams: true },
  ]
)
cdad2_agent.skip_confirmation!
cdad2_agent.save!
cdad2_agent.territorial_roles.create!(territory: territory_gironde)

cdad2_admin = Agent.new(
  email: "cdad2_admin@cdad.fr",
  uid: "cdad2_admin@cdad.fr",
  first_name: "Admin",
  last_name: "CDAD2",
  password: "Rdvservicepublictest1!",
  services: [service_cdad],
  invitation_accepted_at: 10.days.ago,
  roles_attributes: [
    { organisation: org_cdad2, access_level: AgentRole::ACCESS_LEVEL_ADMIN },
  ],
  agent_territorial_access_rights_attributes: [
    { territory: territory_gironde, allow_to_manage_teams: true },
  ]
)
cdad2_admin.skip_confirmation!
cdad2_admin.save!
cdad2_admin.territorial_roles.create!(territory: territory_gironde)
# Intervenants

cdad_intervenant1 = Agent.new(
  last_name: "Avocat 1",
  services: [service_cdad],
  roles_attributes: [
    { organisation: org_cdad1, access_level: AgentRole::ACCESS_LEVEL_INTERVENANT },
  ],
  agent_territorial_access_rights_attributes: [
    { territory: territory_gironde },
  ]
)
cdad_intervenant1.save!

cdad_intervenant2 = Agent.new(
  last_name: "Avocat 2",
  services: [service_cdad],
  roles_attributes: [
    { organisation: org_cdad1, access_level: AgentRole::ACCESS_LEVEL_INTERVENANT },
  ],
  agent_territorial_access_rights_attributes: [
    { territory: territory_gironde },
  ]
)
cdad_intervenant2.save!

cdad_intervenant3 = Agent.new(
  last_name: "Avocat 3",
  services: [service_cdad],
  roles_attributes: [
    { organisation: org_cdad2, access_level: AgentRole::ACCESS_LEVEL_INTERVENANT },
  ],
  agent_territorial_access_rights_attributes: [
    { territory: territory_gironde },
  ]
)
cdad_intervenant3.save!

## Lieux
lieu1_bordeaux = Lieu.create!(
  name: "Point-justice du TJ de BORDEAUX",
  organisation: org_cdad1,
  latitude: 44.8365553,
  longitude: -0.5803633,
  availability: :enabled,
  phone_number: "05.47.33.91.17",
  phone_number_formatted: "+33547339117",
  address: "30 rue des Frères Bonie, BORDEAUX, 33000"
)
Lieu.create!(
  name: "Point-justice de LANGON",
  organisation: org_cdad2,
  latitude: 44.5615,
  longitude: -0.1523,
  availability: :enabled,
  phone_number: "05.57.36.25.54",
  phone_number_formatted: "+330557362554",
  address: "Résidence de l'Horloge, Place de l'horloge, LANGON, 33210"
)

## Plages d'Ouvertures

PlageOuverture.create!(
  title: "Permanence classique Avocat",
  organisation_id: org_cdad1.id,
  agent_id: cdad_intervenant1.id,
  lieu_id: lieu1_bordeaux.id,
  motif_ids: [motif1_cdad1.id],
  first_day: Date.tomorrow,
  start_time: Tod::TimeOfDay.new(8),
  end_time: Tod::TimeOfDay.new(12),
  recurrence: Montrose.every(:week, day: [1, 2], interval: 1, starts: Date.tomorrow, on: %i[monday tuesday])
)

PlageOuverture.create!(
  title: "Permanence classique Avocat",
  organisation_id: org_cdad1.id,
  agent_id: cdad_intervenant2.id,
  lieu_id: lieu1_bordeaux.id,
  motif_ids: [motif1_cdad1.id],
  first_day: Date.tomorrow,
  start_time: Tod::TimeOfDay.new(8),
  end_time: Tod::TimeOfDay.new(12),
  recurrence: Montrose.every(:week, day: [4], interval: 1, starts: Date.tomorrow, on: %i[thursday])
)
