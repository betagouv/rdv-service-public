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
  new_domain_beta: true
)

# MOTIFS Conseiller Numérique
Motif.create!(
  name: "Accompagnement individuel",
  color: "#99CC99",
  default_duration_in_min: 60,
  location_type: :public_office,
  reservable_online: true,
  organisation: org_cnfs,
  service: service_cnfs
)

Motif.create!(
  name: "Atelier collectif",
  color: "#4A86E8",
  default_duration_in_min: 120,
  location_type: :public_office,
  collectif: true,
  organisation: org_cnfs,
  service: service_cnfs
)

agent_cnfs = Agent.new(
  email: "camille-clavier@demo.rdv-solidarites.fr",
  uid: "camille-clavier@demo.rdv-solidarites.fr",
  first_name: "Camille",
  last_name: "Clavier",
  password: "123456",
  service_id: service_cnfs.id,
  invitation_accepted_at: 1.day.ago,
  roles_attributes: [{ organisation: org_cnfs, level: AgentRole::LEVEL_ADMIN }],
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
