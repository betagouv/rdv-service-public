# frozen_string_literal: true

# In case of changes here please make sure rdv_solidarites_model_id didnt change in rdv-insertion seed or update them

# Motif Categories

orientation_category = MotifCategory.create!(short_name: "rsa_orientation", name: "RSA orientation")
accompagnement_category = MotifCategory.create!(short_name: "rsa_accompagnement", name: "RSA accompagnement")

# Territories
territory_drome = Territory.create!(
  departement_number: "26",
  name: "Drôme",
  sms_provider: "netsize",
  sms_configuration: "login:pwd"
)
territory_yonne = Territory.create!(
  departement_number: "89",
  name: "Yonne",
  sms_provider: "netsize",
  sms_configuration: "login:pwd"
)

# Organisations
org_drome1 = Organisation.create!(
  name: "Plateforme mutualisée d'orientation",
  phone_number: "0475796991",
  human_id: "plateforme-mutualisee-orientation-drome",
  territory: territory_drome
)
org_drome2 = Organisation.create!(
  name: "PLIE Valence",
  phone_number: "0101010102",
  human_id: "plie-valence",
  territory: territory_drome
)
org_yonne = Organisation.create!(
  name: "UT Avallon",
  phone_number: "0303030303",
  human_id: "ut-avallon",
  territory: territory_yonne
)

# Service
service_rsa = Service.create!(name: "Service RSA", short_name: "RSA")

# MOTIFS Drome
motif1_drome1 = Motif.create!(
  name: "RSA - Orientation : rdv sur site",
  color: "#00ffff",
  default_duration_in_min: 60,
  organisation: org_drome1,
  bookable_publicly: true,
  max_public_booking_delay: 2_629_746,
  service: service_rsa,
  restriction_for_rdv:
   "Avant votre prise de RDV, veuillez vérifier que  :\r\n- vous percevez RSA\r\n- vous avez effectué votre Déclaration Trimestrielle de Revenus",
  instruction_for_rdv:
   "Avant le RDV  :\r\n- pensez à vous munir d'un masque \r\n- apporter votre CV à jour ainsi que vos documents justifiant de votre inscription à Pôle Emploi",
  for_secretariat: true,
  custom_cancel_warning_message: "Ce RDV est obligatoire",
  motif_category: orientation_category
)
motif2_drome1 = Motif.create!(
  name: "RSA accompagnement",
  color: "#000000",
  default_duration_in_min: 30,
  organisation: org_drome1,
  bookable_publicly: true,
  service: service_rsa,
  custom_cancel_warning_message: "",
  collectif: false,
  motif_category: accompagnement_category
)
motif_drome2 = Motif.create!(
  name: "RSA - Orientation : rdv sur site",
  color: "#00ffff",
  default_duration_in_min: 60,
  organisation: org_drome2,
  bookable_publicly: true,
  max_public_booking_delay: 2_629_746,
  service: service_rsa,
  for_secretariat: true,
  custom_cancel_warning_message: "Ce RDV est obligatoire",
  motif_category: orientation_category
)

# MOTIFS Yonne
motif_yonne_physique = Motif.create!(
  name: "RSA - Codiagnostic d'orientation",
  color: "#000000",
  default_duration_in_min: 30,
  organisation: org_yonne,
  service: service_rsa,
  for_secretariat: true,
  motif_category: orientation_category
)
motif_yonne_telephone = Motif.create!(
  name: "RSA - Orientation : rdv téléphonique",
  color: "#000000",
  default_duration_in_min: 30,
  organisation: org_yonne,
  service: service_rsa,
  for_secretariat: true,
  location_type: "phone",
  motif_category: orientation_category
)

# Agent
agent_orgs_rdv_insertion = Agent.new(
  email: "alain.sertion@rdv-insertion-demo.fr",
  uid: "alain.sertion@rdv-insertion-demo.fr",
  first_name: "Alain",
  last_name: "Sertion",
  password: "123456",
  service_id: service_rsa.id,
  invitation_accepted_at: 10.days.ago,
  roles_attributes: [
    { organisation: org_drome1, level: AgentRole::LEVEL_ADMIN },
    { organisation: org_drome2, level: AgentRole::LEVEL_ADMIN },
    { organisation: org_yonne, level: AgentRole::LEVEL_ADMIN },
  ],
  agent_territorial_access_rights_attributes: [
    { territory: territory_drome, allow_to_manage_teams: true },
    { territory: territory_yonne, allow_to_manage_teams: true },
  ]
)
agent_orgs_rdv_insertion.skip_confirmation!
agent_orgs_rdv_insertion.save!
agent_orgs_rdv_insertion.territorial_roles.create!(territory: territory_drome)
agent_orgs_rdv_insertion.territorial_roles.create!(territory: territory_yonne)

## Lieux
lieu_org_drome1_crest = Lieu.create!(
  name: "AIRE - Plate-forme mutualisée d'orientation - Département de la Drôme",
  organisation: org_drome1,
  latitude: 44.733748,
  longitude: 5.004262,
  availability: :enabled,
  phone_number: "04.75.79.69.91",
  phone_number_formatted: "+33475796991",
  address: "Rue a Combattants Outre Mer, Crest, 26400"
)
lieu_org_drome1_valence = Lieu.create!(
  name: "Le 114 - Plate -forme mutualisée d'orientation - Département de la Drôme",
  organisation: org_drome1,
  latitude: 44.918859,
  longitude: 4.919825,
  availability: :enabled,
  phone_number: "04.75.79.69.91",
  phone_number_formatted: "+33475796991",
  address: "114 Rue de la Forêt, Valence, 26000"
)
lieu_org_yonne = Lieu.create!(
  name: "PE Avallon",
  organisation: org_yonne,
  old_address: "3 Rue Joubert, Auxerre, 89000, 89, Yonne, Bourgogne-Franche-Comté",
  latitude: 47.796413,
  longitude: 3.572016,
  availability: :enabled,
  address: "3 Rue Joubert, Auxerre, 89000"
)

## Plages d'Ouvertures

_plage_ouverture_org_drome_lieu1_alain_classique = PlageOuverture.create!(
  title: "Permanence classique",
  organisation_id: org_drome1.id,
  agent_id: agent_orgs_rdv_insertion.id,
  lieu_id: lieu_org_drome1_valence.id,
  motif_ids: [motif1_drome1.id, motif2_drome1.id],
  first_day: Date.tomorrow,
  start_time: Tod::TimeOfDay.new(8),
  end_time: Tod::TimeOfDay.new(12),
  recurrence: Montrose.every(:week, day: [1, 2], interval: 1, starts: Date.tomorrow, on: %i[monday tuesday])
)
_plage_ouverture_org_drome_lieu2_alain_classique = PlageOuverture.create!(
  title: "Permanence classique",
  organisation_id: org_drome1.id,
  agent_id: agent_orgs_rdv_insertion.id,
  lieu_id: lieu_org_drome1_crest.id,
  motif_ids: [motif_drome2.id],
  first_day: Date.tomorrow,
  start_time: Tod::TimeOfDay.new(8),
  end_time: Tod::TimeOfDay.new(12),
  recurrence: Montrose.every(:week, day: [3, 4], interval: 1, starts: Date.tomorrow, on: %i[wednesday thursday])
)
_plage_ouverture_org_yonne_alain_classique = PlageOuverture.create!(
  title: "Permanence classique",
  organisation_id: org_drome1.id,
  agent_id: agent_orgs_rdv_insertion.id,
  lieu_id: lieu_org_yonne.id,
  motif_ids: [motif_yonne_physique.id, motif_yonne_telephone.id],
  first_day: Date.tomorrow,
  start_time: Tod::TimeOfDay.new(8),
  end_time: Tod::TimeOfDay.new(12),
  recurrence: Montrose.every(:week, day: [5], interval: 1, starts: Date.tomorrow, on: %i[friday])
)

# WEBHOOKS
WebhookEndpoint.create!(
  target_url: "http://localhost:8000/rdv_solidarites_webhooks",
  secret: "rdv-solidarites",
  organisation_id: org_drome1.id,
  subscriptions: %w[rdv user user_profile organisation motif lieu agent agent_role referent_assignation]
)
WebhookEndpoint.create!(
  target_url: "http://localhost:8000/rdv_solidarites_webhooks",
  secret: "rdv-solidarites",
  organisation_id: org_drome2.id,
  subscriptions: %w[rdv user user_profile organisation motif lieu agent agent_role referent_assignation]
)
WebhookEndpoint.create!(
  target_url: "http://localhost:8000/rdv_solidarites_webhooks",
  secret: "rdv-solidarites",
  organisation_id: org_yonne.id,
  subscriptions: %w[rdv user user_profile organisation motif lieu agent agent_role referent_assignation]
)
