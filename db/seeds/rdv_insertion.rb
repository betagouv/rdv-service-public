# In case of changes here please make sure rdv_solidarites_model_id didnt change in rdv-insertion seed or update them

# Motif Categories

orientation_category = MotifCategory.create!(short_name: "rsa_orientation", name: "RSA orientation")
accompagnement_category = MotifCategory.create!(short_name: "rsa_accompagnement", name: "RSA accompagnement")

MotifCategory.create!(short_name: "rsa_accompagnement_sociopro", name: "RSA accompagnement socio-pro")
MotifCategory.create!(short_name: "rsa_accompagnement_social", name: "RSA accompagnement social")
MotifCategory.create!(short_name: "rsa_cer_signature", name: "RSA signature CER")
MotifCategory.create!(short_name: "rsa_follow_up", name: "RSA suivi")
MotifCategory.create!(short_name: "rsa_insertion_offer", name: "RSA offre insertion pro")
MotifCategory.create!(short_name: "rsa_orientation_on_phone_platform", name: "RSA orientation sur plateforme téléphonique")
MotifCategory.create!(short_name: "rsa_atelier_collectif_mandatory", name: "RSA Atelier collectif obligatoire")
MotifCategory.create!(short_name: "rsa_atelier_rencontres_pro", name: "RSA Atelier rencontres professionnelles")
MotifCategory.create!(short_name: "rsa_atelier_competences", name: "RSA Atelier compétences")
MotifCategory.create!(short_name: "rsa_main_tendue", name: "RSA Main Tendue")
MotifCategory.create!(short_name: "rsa_spie", name: "RSA SPIE")
MotifCategory.create!(short_name: "rsa_integration_information", name: "RSA Information d'intégration")

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
  territory: territory_drome,
  verticale: :rdv_insertion
)
org_drome2 = Organisation.create!(
  name: "PLIE Valence",
  phone_number: "0101010102",
  territory: territory_drome,
  verticale: :rdv_insertion
)
org_yonne = Organisation.create!(
  name: "UT Avallon",
  phone_number: "0303030303",
  territory: territory_yonne,
  verticale: :rdv_insertion
)

# Service
service_rsa = Service.create!(name: "Service RSA", short_name: "RSA")
territory_drome.services << service_rsa
territory_yonne.services << service_rsa

# MOTIFS Drome
motif1_drome1 = Motif.create!(
  name: "RSA - Orientation : rdv sur site",
  color: "#00ffff",
  default_duration_in_min: 60,
  organisation: org_drome1,
  bookable_by: :agents_and_prescripteurs_and_invited_users,
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
  bookable_by: :agents_and_prescripteurs_and_invited_users,
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
  bookable_by: :agents_and_prescripteurs_and_invited_users,
  max_public_booking_delay: 2_629_746,
  service: service_rsa,
  for_secretariat: true,
  custom_cancel_warning_message: "Ce RDV est obligatoire",
  motif_category: orientation_category
)
motif_convoc_drome1 = Motif.create!(
  name: "Convocation RSA - Orientation : rdv sur site",
  color: "#00ffff",
  default_duration_in_min: 60,
  organisation: org_drome1,
  bookable_by: :agents,
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
  password: ENV["DB_SEEDS_USERS_AND_AGENTS_PASSWORD"],
  invitation_accepted_at: 10.days.ago,
  roles_attributes: [
    { organisation: org_drome1, access_level: AgentRole::ACCESS_LEVEL_ADMIN },
    { organisation: org_drome2, access_level: AgentRole::ACCESS_LEVEL_ADMIN },
    { organisation: org_yonne, access_level: AgentRole::ACCESS_LEVEL_ADMIN },
  ],
  agent_territorial_access_rights_attributes: [
    { territory: territory_drome, allow_to_manage_teams: true },
    { territory: territory_yonne, allow_to_manage_teams: true },
  ]
)
agent_orgs_rdv_insertion.services = [service_rsa]
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
lieu_org_drome2_valence = Lieu.create!(
  name: "PLIE Valence Drome2 - Département de la Drôme",
  organisation: org_drome2,
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
  latitude: 47.796413,
  longitude: 3.572016,
  availability: :enabled,
  address: "3 Rue Joubert, Auxerre, 89000"
)

## Plages d'Ouvertures

_plage_ouverture_org_drome1_lieu1_alain_classique = PlageOuverture.create!(
  title: "Permanence classique",
  organisation_id: org_drome1.id,
  agent_id: agent_orgs_rdv_insertion.id,
  lieu_id: lieu_org_drome1_valence.id,
  motif_ids: [motif1_drome1.id, motif2_drome1.id, motif_convoc_drome1.id],
  first_day: Date.tomorrow,
  start_time: Tod::TimeOfDay.new(8),
  end_time: Tod::TimeOfDay.new(12),
  recurrence: Montrose.every(:week, day: [1, 2], interval: 1, starts: Date.tomorrow, on: %i[monday tuesday])
)
_plage_ouverture_org_drome1_lieu2_alain_classique = PlageOuverture.create!(
  title: "Permanence classique",
  organisation_id: org_drome1.id,
  agent_id: agent_orgs_rdv_insertion.id,
  lieu_id: lieu_org_drome1_crest.id,
  motif_ids: [motif2_drome1.id],
  first_day: Date.tomorrow,
  start_time: Tod::TimeOfDay.new(8),
  end_time: Tod::TimeOfDay.new(12),
  recurrence: Montrose.every(:week, day: [3], interval: 1, starts: Date.tomorrow, on: %i[wednesday])
)
_plage_ouverture_org_drome2_lieu1_alain_classique = PlageOuverture.create!(
  title: "Permanence classique",
  organisation_id: org_drome2.id,
  agent_id: agent_orgs_rdv_insertion.id,
  lieu_id: lieu_org_drome2_valence.id,
  motif_ids: [motif_drome2.id],
  first_day: Date.tomorrow,
  start_time: Tod::TimeOfDay.new(8),
  end_time: Tod::TimeOfDay.new(12),
  recurrence: Montrose.every(:week, day: [4], interval: 1, starts: Date.tomorrow, on: %i[thursday])
)
_plage_ouverture_org_yonne_alain_classique = PlageOuverture.create!(
  title: "Permanence classique",
  organisation_id: org_yonne.id,
  agent_id: agent_orgs_rdv_insertion.id,
  lieu_id: lieu_org_yonne.id,
  motif_ids: [motif_yonne_physique.id, motif_yonne_telephone.id],
  first_day: Date.tomorrow,
  start_time: Tod::TimeOfDay.new(8),
  end_time: Tod::TimeOfDay.new(12),
  recurrence: Montrose.every(:week, day: [5], interval: 1, starts: Date.tomorrow, on: %i[friday])
)

# Users
user1 = User.create!(
  email: "jean.rsavalence@testinvitation.fr",
  address: "60 avenue de Chabeuil 26000 Valence",
  first_name: "Jean",
  last_name: "RSAValence",
  phone_number: "0601020304",
  created_through: "agent_creation_api",
  invited_through: "external",
  birth_date: 30.years.ago,
  organisations: [org_drome1, org_drome2]
)
user1.set_rdv_invitation_token!
user1.save!

user2 = User.create!(
  email: "jean.rsaAuxerre@testinvitation.fr",
  address: "12 Rue Joubert, Auxerre, 89000",
  first_name: "Jean",
  last_name: "RSAAuxerre",
  created_through: "agent_creation_api",
  invited_through: "external",
  birth_date: 30.years.ago,
  organisations: [org_yonne]
)
user2.set_rdv_invitation_token!
user2.save!

# On reprend ci dessous les paramêtres que Rdvi utilise pour générer l'url d'invitation.
# le code est ici https://github.com/betagouv/rdv-insertion/blob/9c03e5a6c720a88826e84ca854fd5ccb6135569a/app/services/invitations/compute_link.rb#L2

dataset = [{
  user: user1,
  organisation: org_drome1,
  motif: motif1_drome1,
  city_code: "26362",
  street_ban_id: "26362_1450",
  longitude: "4.901427",
  latitude: "44.931348",
}, {
  user: user2,
  organisation: org_yonne,
  motif: motif_yonne_physique,
  city_code: "89024",
  street_ban_id: "89024_3940",
  longitude: "3.572903",
  latitude: "47.795585",
},]

dataset.each do |data|
  user = data[:user]
  organisation = data[:organisation]
  motif = data[:motif]

  city_code = data[:city_code]
  street_ban_id = data[:street_ban_id]
  longitude = data[:longitude]
  latitude = data[:latitude]
  invitation_token = user.rdv_invitation_token
  organisation_id = organisation.id
  motif_category_short_name = motif.motif_category.short_name
  address = user.address
  departement = organisation.territory.departement_number

  attributes = {
    longitude: longitude,
    latitude: latitude,
    city_code: city_code,
    street_ban_id: street_ban_id,
    departement: departement,
    address: address,
    invitation_token: invitation_token,
    organisation_ids: [organisation_id],
    motif_category_short_name: motif_category_short_name,
  }
  link = "#{ENV['HOST']}/prendre_rdv?#{attributes.to_query}"

  # !!! Le lien d'invitation est disponible dans la note des users
  # jean.rsavalence@testinvitation.fr et jean.rsaAuxerre@testinvitation.fr
  user.annotate!(link, territory: organisation.territory)
end

rdv_insertion_logo_base64 = "data:image/svg+xml;base64,PD94bWwgdmVyc2lvbj0iMS4wIiBlbmNvZGluZz0iVVRGLTgiIHN0YW5kYWxvbmU9Im5vIj8+CjxzdmcKICAgaWQ9IkNhbHF1ZV8xIgogICB2aWV3Qm94PSIwIDAgNDgzLjMzIDQ4My4zMyIKICAgdmVyc2lvbj0iMS4xIgogICB3aWR0aD0iNDgzLjMyOTk5IgogICBoZWlnaHQ9IjQ4My4zMjk5OSIKICAgeG1sbnM9Imh0dHA6Ly93d3cudzMub3JnLzIwMDAvc3ZnIgogICB4bWxuczpzdmc9Imh0dHA6Ly93d3cudzMub3JnLzIwMDAvc3ZnIj4KICA8ZGVmcwogICAgIGlkPSJkZWZzMSI+CiAgICA8c3R5bGUKICAgICAgIGlkPSJzdHlsZTEiPi5jbHMtMXtmaWxsOiNlYzRjNGM7fS5jbHMtMntmaWxsOiMwODNiNjY7fTwvc3R5bGU+CiAgPC9kZWZzPgogIDxnCiAgICAgaWQ9ImcxOCI+CiAgICA8ZwogICAgICAgaWQ9ImcxOSIKICAgICAgIHRyYW5zZm9ybT0idHJhbnNsYXRlKC0xMC45MTcyMTMsLTAuMDAzMDUwMDYpIj4KICAgICAgPHBhdGgKICAgICAgICAgY2xhc3M9ImNscy0yIgogICAgICAgICBkPSJtIDE5My45Nyw0MTEuMzkgOC4wMywtMS45NyBjIDAsMCAxOS4xNiwtNy42OSAyNC41NCwtMzYuNzEgNS4zOCwtMjkuMDEgMzAuNTMsLTQ4LjU2IDU4LjY2LC00MC4yNyAyMC4yNCwtMi44OCA1LjQyLC0zMy45NyAtMjUuNjYsLTI1LjU0IC0yNS42OCw2Ljk3IC0zOC42NCwxMi45NiAtNDguNywxMC4wOCAtMy4zMSwtMC45NiAtNS44MSwtMy42NyAtNi41MSwtNy4wNCAtOC4zOCwtNDAuNyAtMjUuMTcsLTEyMS45NiAtMjcuMTcsLTEyOC45NiAtMi40LC04LjM2IC03LjkzLC0xMC44IC0xMy45MiwtOS42MyAtNy4wMywwLjg5IC03LjQ4LDguMTkgLTcuNjMsMTIuOTEgMCw2LjA2IDQuMDksNTQuMTggNi4yOCw3OS40NyAtMS45MiwtNy45NyAtNi4zOSwtMTUuODkgLTE2LjYsLTE1LjAxIC0xMC40OCwwLjg4IC0xMi4zNSwxMy44MSAtMTIuMTEsMjQuMjUgLTIuMTIsLTguMjIgLTcuNDQsLTE2LjQ5IC0yMC42NiwtMTIuNDkgLTQuNjQsMS4zOSAtNi43OCw4LjE1IC03LjUxLDE2Ljc2IGwgLTAuMzIsLTAuNDcgLTI3LjA0LC00MS4yMyBDIDY1LjIzLDIxNi41OSA3MC41MSwxOTEuMTcgODkuNDYsMTc4Ljc0IEwgMjYyLjQ3LDY1LjI4IGMgMTUuNDMsLTEwLjEzIDM1LjU5LC03LjMxIDQ3LjczLDUuNzkgbCAtNC44OCwxLjIgYyAwLDAgLTE5LjIxLDcuNzIgLTI0LjYxLDM2Ljg3IC01LjM5LDI5LjEzIC0zMC42LDQ4Ljc2IC01OC43OSw0MC40MyAtMjAuMjksMi45IC01LjQ0LDM0LjEyIDI1LjcxLDI1LjY2IDI1Ljc2LC03LjAxIDM4Ljc1LC0xMy4wMyA0OC44NSwtMTAuMTEgMy4zLDAuOTUgNS44LDMuNjYgNi41LDcuMDQgOC4zOSw0MC44NiAyNS4yMywxMjIuNDkgMjcuMjMsMTI5LjUxIDIuNDEsOC40MSA3Ljk1LDEwLjg2IDEzLjk2LDkuNjcgNy4wNSwtMC45IDcuNSwtOC4yMiA3LjY0LC0xMi45NyAwLC02LjA4IC00LjEsLTU0LjQgLTYuMjksLTc5LjggMS45Myw4LjAxIDYuNCwxNS45NSAxNi42NCwxNS4wOCAxMC41MSwtMC44OSAxMi4zOCwtMTMuODcgMTIuMTQsLTI0LjM2IDIuMTIsOC4yNSA3LjQ2LDE2LjU2IDIwLjcyLDEyLjU1IDMuNzEsLTEuMTIgNS44MiwtNS42NyA2LjksLTExLjg1IGwgMC40MSwwLjYzIDYuMjIsOS40OCB2IDAgYyAwLDAgMTguOTYsMjguOTEgMTguOTYsMjguOTEgMTIuNDMsMTguOTQgNy4xNCw0NC4zNyAtMTEuODEsNTYuOCBMIDI0NS4zMSw0MTcuNTUgYyAtMTUuODcsMTAuNDEgLTM2LjM2LDguMTkgLTQ5LjY1LC00LjE5IC0wLjY2LC0wLjYxIC0xLjMsLTEuMjUgLTEuOTIsLTEuOTEgeiIKICAgICAgICAgaWQ9InBhdGgxNSIgLz4KICAgICAgPGcKICAgICAgICAgaWQ9ImcxNyI+CiAgICAgICAgPHBhdGgKICAgICAgICAgICBjbGFzcz0iY2xzLTEiCiAgICAgICAgICAgZD0ibSAyNTIuMzIsMjM4LjY5IC0zOS4wNCwtMzAuMzYgaCA4MS4wOCBsIC0zOS4wNCwzMC4zNiBjIC0wLjg4LDAuNjkgLTIuMTIsMC42OSAtMywwIHoiCiAgICAgICAgICAgaWQ9InBhdGgxNiIgLz4KICAgICAgICA8cGF0aAogICAgICAgICAgIGNsYXNzPSJjbHMtMSIKICAgICAgICAgICBkPSJtIDI5OS45NywyMTMuNDYgdiA0OS45NCBjIDAsNi40IC01LjE5LDExLjU5IC0xMS41OSwxMS41OSBoIC02OS4xMyBjIC02LjQsMCAtMTEuNTksLTUuMTkgLTExLjU5LC0xMS41OSB2IC00OS45NCBjIDAsLTAuMjQgMC4wMiwtMC40OCAwLjA1LC0wLjcyIGwgNDIuMTMsMzIuNzcgYyAyLjMzLDEuODEgNS42LDEuODEgNy45MywwIGwgNDIuMTMsLTMyLjc3IGMgMC4wNCwwLjI0IDAuMDUsMC40OCAwLjA1LDAuNzMgeiIKICAgICAgICAgICBpZD0icGF0aDE3IiAvPgogICAgICA8L2c+CiAgICA8L2c+CiAgPC9nPgo8L3N2Zz4K" # rubocop:disable Layout/LineLength

application = Doorkeeper::Application.new(
  name: "RDV Insertion",
  uid: "zC24y16rYftyrBgTj8h08g1NZKkwStXWe3E_lLMGoHc",
  redirect_uri: "http://localhost:8000/auth/rdvservicepublic/callback",
  post_logout_redirect_uri: "http://localhost:8000/",
  logo_base64: rdv_insertion_logo_base64
)

test_secret = "development-EdtuETfEK5Lr_--kx6S_QlItIJov-iThILw6M8IyTus" # Pour le développement en local uniquement
application.secret_strategy.store_secret(application, :secret, test_secret)
application.save!

# WEBHOOKS
WebhookEndpoint.create!(
  target_url: "#{ENV.fetch('RDV_INSERTION_HOST', 'http://localhost:8000')}/rdv_solidarites_webhooks",
  secret: ENV.fetch("RDV_INSERTION_SECRET", "rdv-solidarites"),
  organisation_id: org_drome1.id,
  subscriptions: %w[rdv user user_profile organisation motif lieu agent agent_role referent_assignation]
)
WebhookEndpoint.create!(
  target_url: "#{ENV.fetch('RDV_INSERTION_HOST', 'http://localhost:8000')}/rdv_solidarites_webhooks",
  secret: ENV.fetch("RDV_INSERTION_SECRET", "rdv-solidarites"),
  organisation_id: org_drome2.id,
  subscriptions: %w[rdv user user_profile organisation motif lieu agent agent_role referent_assignation]
)
WebhookEndpoint.create!(
  target_url: "#{ENV.fetch('RDV_INSERTION_HOST', 'http://localhost:8000')}/rdv_solidarites_webhooks",
  secret: ENV.fetch("RDV_INSERTION_SECRET", "rdv-solidarites"),
  organisation_id: org_yonne.id,
  subscriptions: %w[rdv user user_profile organisation motif lieu agent agent_role referent_assignation]
)
