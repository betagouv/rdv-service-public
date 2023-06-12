# frozen_string_literal: true

territory_cnfs = Territory.create!(
  departement_number: "CN",
  name: "Conseillers Numériques",
  sms_provider: "netsize",
  sms_configuration: "login:pwd"
)

service_cnfs = Service.create!(name: Service::CONSEILLER_NUMERIQUE, short_name: Service::CONSEILLER_NUMERIQUE)

org_cnfs = Organisation.create!(
  name: "Mediathèque Paris Nord",
  phone_number: "0123456789",
  human_id: "mediatheque-paris-nord",
  territory: territory_cnfs,
  external_id: "666",
  verticale: :rdv_aide_numerique
)

# MOTIFS Conseiller Numérique

motif_accompagnement_individuel = Motif.create!(
  name: "Accompagnement individuel",
  color: "#99CC99",
  default_duration_in_min: 60,
  location_type: :public_office,
  bookable_publicly: true,
  organisation: org_cnfs,
  service: service_cnfs
)

motif_atelier_collectif = Motif.create!(
  name: "Atelier collectif",
  color: "#4A86E8",
  default_duration_in_min: 120,
  location_type: :public_office,
  collectif: true,
  bookable_publicly: true,
  organisation: org_cnfs,
  service: service_cnfs
)

cnfs_lieu = Lieu.create!(
  name: "Médiathèque Françoise Sagan",
  organisation: org_cnfs,
  latitude: 44.918859,
  longitude: 4.919825,
  availability: :enabled,
  phone_number: "01 53 24 69 70",
  address: "8 Rue Léon Schwartzenberg, 75010 Paris"
)

agent_cnfs = Agent.new(
  email: "camille-clavier@demo.rdv-solidarites.fr",
  uid: "camille-clavier@demo.rdv-solidarites.fr",
  first_name: "Camille",
  last_name: "Clavier",
  password: "123456",
  service_id: service_cnfs.id,
  invitation_accepted_at: 1.day.ago,
  roles_attributes: [{ organisation: org_cnfs, access_level: AgentRole::ACCESS_LEVEL_ADMIN }],
  agent_territorial_access_rights_attributes: [{
    territory: territory_cnfs,
    allow_to_manage_teams: false,
    allow_to_manage_access_rights: false,
    allow_to_invite_agents: false,
    allow_to_download_metrics: false,
  }]
)
agent_cnfs.skip_confirmation!
agent_cnfs.save!

PlageOuverture.create!(
  title: "Permanence d'accompagnement individuel",
  organisation_id: org_cnfs.id,
  agent_id: agent_cnfs.id,
  lieu_id: cnfs_lieu.id,
  motif_ids: [motif_accompagnement_individuel.id],
  first_day: Date.tomorrow,
  start_time: Tod::TimeOfDay.new(8),
  end_time: Tod::TimeOfDay.new(12),
  recurrence: Montrose.every(:week, day: [1, 2, 3, 4, 5], interval: 1, starts: Date.tomorrow, on: %i[monday tuesday thursday friday])
)

20.times do |i|
  Rdv.create!(
    starts_at: Time.zone.today + 17.hours + i.weeks,
    duration_in_min: 60,
    motif_id: motif_atelier_collectif.id,
    lieu: cnfs_lieu,
    organisation_id: org_cnfs.id,
    agent_ids: [agent_cnfs.id],
    users_count: 0,
    user_ids: []
  )
end
