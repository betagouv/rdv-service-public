# frozen_string_literal: true

require "csv"

# TERRITORIEs

territory75 = Territory.create!(
  departement_number: "75",
  name: "Paris",
  sms_provider: "netsize",
  sms_configuration: "login:pwd"
)
territory62 = Territory.create!(
  departement_number: "62",
  name: "Pas-de-Calais",
  sms_provider: "netsize",
  sms_configuration: "login:pwd"
)

# ORGANISATIONS & SECTORS

Organisation.skip_callback(:create, :after, :notify_admin_organisation_created)
org_paris_nord = Organisation.create!(
  name: "MDS Paris Nord",
  phone_number: "0123456789",
  human_id: "paris-nord",
  territory: territory75
)

human_id_map = [
  { human_id: "1030", name: "MDS Arques" },
  { human_id: "1031", name: "MDS Arras Nord" },
  { human_id: "1032", name: "MDS Arras Sud" },
  { human_id: "1033", name: "MDS Avion" },
  { human_id: "1042", name: "MDS Etaples" },
  { human_id: "1043", name: "MDS Hénin-Beaumont" },
  { human_id: "1052", name: "MDS Outreau" },
  { human_id: "1050", name: "MDS Berck" },
  { human_id: "1036", name: "MDS Boulogne-sur-Mer" },
  { human_id: "1037", name: "MDS Bruay la Buissière" },
  { human_id: "1038", name: "MDS Bully les Mines" },
  { human_id: "1035", name: "MDS Béthune" },
  { human_id: "1039", name: "MDS Calais 1" },
  { human_id: "1040", name: "MDS Calais 2" },
  { human_id: "1041", name: "MDS Carvin" },
  { human_id: "1046", name: "MDS Lens 1" },
  { human_id: "1047", name: "MDS Lens 2" },
  { human_id: "1049", name: "MDS Lillers" },
  { human_id: "1048", name: "MDS Liévin" },
  { human_id: "1044", name: "MDS Marconne" },
  { human_id: "1051", name: "MDS Noeux les Mines" },
  { human_id: "1053", name: "MDS St Martin les Boulogne" },
  { human_id: "1054", name: "MDS St Omer" },
  { human_id: "1055", name: "MDS St Pol sur Ternoise" },
].to_h do |attributes|
  organisation = Organisation.create!(phone_number: "0123456789", territory: territory62, human_id: attributes[:human_id], name: attributes[:name])
  sector = Sector.create!(name: "Secteur de #{attributes[:name][4..]}", human_id: attributes[:human_id], territory: territory62)
  sector.attributions.create!(organisation: organisation, level: SectorAttribution::LEVEL_ORGANISATION)
  [attributes[:human_id], { organisation: organisation, sector: sector }]
end

# Bapaume is created without the organisation-level attribution
org_bapaume = Organisation.create!(phone_number: "0123456789", territory: territory62, human_id: "1034-nord", name: "MDS Bapaume")
sector_bapaume_nord = Sector.create!(name: "Bapaume Nord", human_id: "1034-nord", territory: territory62)
sector_bapaume_sud = Sector.create!(name: "Bapaume Sud", human_id: "1034-sud", territory: territory62)
sector_bapaume_fallback = Sector.create!(name: "Bapaume Entier", human_id: "1034-fallback", territory: territory62)
sector_bapaume_fallback.attributions.create!(organisation: org_bapaume, level: SectorAttribution::LEVEL_ORGANISATION)
human_id_map["1034-nord"] = { organisation: org_bapaume, sector: sector_bapaume_nord }
human_id_map["1034-sud"] = { organisation: org_bapaume, sector: sector_bapaume_sud }
human_id_map["1034-fallback"] = { organisation: org_bapaume, sector: sector_bapaume_fallback }
org_arques = human_id_map["1030"][:organisation]

Organisation.set_callback(:create, :after, :notify_admin_organisation_created)

# SERVICES

service_pmi = Service.create!(name: "PMI (Protection Maternelle Infantile)", short_name: "PMI")
service_social = Service.create!(name: "Service social", short_name: "Service Social")
service_secretariat = Service.create!(name: "Secrétariat", short_name: "Secrétariat")
_service_nouveau = Service.create!(name: "Médico-social", short_name: "Médico-social")

# MOTIFS org_paris_nord

motif_org_paris_nord_pmi_rappel = Motif.create!(
  name: "Être rappelé par la PMI",
  color: "#FF7C00",
  organisation_id: org_paris_nord.id,
  service_id: service_pmi.id,
  bookable_publicly: true,
  location_type: :phone
)
motif_org_paris_nord_pmi_gyneco = Motif.create!(
  name: "Consultation gynécologie / contraception",
  color: "#FF7C00",
  organisation_id: org_paris_nord.id,
  service_id: service_pmi.id,
  bookable_publicly: false,
  location_type: :phone
)
motif_org_paris_nord_pmi_prenatale = Motif.create!(
  name: "Consultation prénatale",
  color: "#CC7C00",
  organisation_id: org_paris_nord.id,
  service_id: service_pmi.id,
  bookable_publicly: true,
  location_type: :public_office
)
motif_org_paris_nord_pmi_prenatale_phone = Motif.create!(
  name: "Consultation prénatale",
  color: "#CC7C00",
  organisation_id: org_paris_nord.id,
  service_id: service_pmi.id,
  bookable_publicly: true,
  location_type: :phone
)
motif_org_paris_nord_pmi_suivi = Motif.create!(
  name: "Suivi après naissance",
  color: "#00FC60",
  organisation_id: org_paris_nord.id,
  service_id: service_pmi.id,
  bookable_publicly: true,
  location_type: :public_office,
  follow_up: true
)
motif_org_paris_nord_pmi_securite = Motif.create!(
  name: "Sécurité du domicile",
  color: "#1010FF",
  organisation_id: org_paris_nord.id,
  service_id: service_pmi.id,
  bookable_publicly: true,
  location_type: :home
)
motif_org_paris_nord_pmi_collectif = Motif.create!(
  name: "Atelier Collectif",
  color: "#1049F3",
  organisation_id: org_paris_nord.id,
  service_id: service_pmi.id,
  collectif: true,
  bookable_publicly: true,
  default_duration_in_min: 60,
  location_type: :public_office
)
_motif_org_paris_nord_social_rappel = Motif.create!(
  name: "Être rappelé par la MDS",
  color: "#FF7C00",
  organisation_id: org_paris_nord.id,
  service_id: service_social.id,
  bookable_publicly: true,
  location_type: :phone
)
_motif_org_paris_nord_social_suivi = Motif.create!(
  name: "Suivi RSA",
  color: "#CC7C00",
  organisation_id: org_paris_nord.id,
  service_id: service_social.id,
  bookable_publicly: true,
  location_type: :public_office,
  follow_up: true
)
_motif_org_paris_nord_social_droits = Motif.create!(
  name: "Droits sociaux",
  color: "#00FC60",
  organisation_id: org_paris_nord.id,
  service_id: service_social.id,
  bookable_publicly: true,
  location_type: :public_office
)
_motif_org_paris_nord_social_collectif = Motif.create!(
  name: "Forum",
  color: "#113C65",
  organisation_id: org_paris_nord.id,
  service_id: service_social.id,
  collectif: true,
  bookable_publicly: true,
  default_duration_in_min: 120,
  location_type: :public_office
)

# MOTIFS organisations du 62

motifs = {}
[[:bapaume, org_bapaume], [:arques, org_arques]].each do |seed_id, org|
  motifs[seed_id] ||= {}
  motifs[seed_id][:pmi_rappel] = Motif.create!(
    name: "Être rappelé par la PMI",
    color: "#10FF10",
    organisation_id: org.id,
    service_id: service_pmi.id,
    bookable_publicly: true,
    location_type: :phone
  )
  motifs[seed_id][:pmi_prenatale] = Motif.create!(
    name: "Consultation prénatale",
    color: "#FF1010",
    organisation_id: org.id,
    service_id: service_pmi.id,
    bookable_publicly: true,
    location_type: :public_office
  )
end

now = Time.zone.now
motifs_attributes = 1000.times.map do |i|
  {
    created_at: now,
    updated_at: now,
    name: "motif_#{i}",
    color: "#000000",
    organisation_id: org_arques.id,
    service_id: service_secretariat.id,
    bookable_by: :everyone,
    location_type: :public_office,
  }
end
Motif.insert_all!(motifs_attributes) # rubocop:disable Rails/SkipsModelValidations

# LIEUX

lieu_org_paris_nord_bolivar = Lieu.create!(
  name: "MDS Bolivar",
  organisation: org_paris_nord,
  availability: :enabled,
  address: "126 Avenue Simon Bolivar, 75019, Paris",
  latitude: 48.8809263,
  longitude: 2.3739077
)
lieu_org_paris_nord_bd_aubervilliers = Lieu.create!(
  name: "MDS Bd Aubervilliers",
  organisation: org_paris_nord,
  availability: :enabled,
  address: "18 Boulevard d'Aubervilliers, 75019 Paris",
  latitude: 48.8882196,
  longitude: 2.3650464
)
lieu_arques_nord = Lieu.create!(
  name: "Maison Arques Nord",
  organisation: org_arques,
  availability: :enabled,
  address: "10 rue du marechal leclerc, 62410 Arques",
  latitude: 50.7406,
  longitude: 2.3103
)
lieu_bapaume_est = Lieu.create!(
  name: "MJC Bapaume Est",
  organisation: org_bapaume,
  availability: :enabled,
  address: "10 rue emile delot, 62450 Arques",
  latitude: 50.1026,
  longitude: 2.8486
)

now = Time.zone.now
lieux_attributes = 100.times.map do |i|
  {
    created_at: now,
    updated_at: now,
    name: "lieu_#{i}",
    organisation_id: org_bapaume.id,
    availability: :enabled,
    address: "Adresse #{i}",
    latitude: 45 + (i.to_f / 100.0),
    longitude: 2 + (i.to_f / 100.0),
  }
end
Lieu.insert_all!(lieux_attributes) # rubocop:disable Rails/SkipsModelValidations

## ZONES
zones_csv_path = Rails.root.join("db/seeds/zones_62.csv")
CSV.read(zones_csv_path, headers: :first_row).each do |row|
  Zone.create!(
    level: row["street_ban_id"].present? ? "street" : "city",
    sector: human_id_map[row["sector_id"]][:sector],
    city_code: row["city_code"],
    city_name: row["city_name"],
    street_name: row["street_name"],
    street_ban_id: row["street_ban_id"]
  )
end

# USERS

user_org_paris_nord_patricia = User.new(
  first_name: "Patricia",
  last_name: "Duroy",
  email: "patricia_duroy@demo.rdv-solidarites.fr",
  birth_date: Date.parse("20/06/1975"),
  password: "123456",
  phone_number: "0101010101",
  organisation_ids: [org_paris_nord.id, org_arques.id],
  created_through: "user_sign_up"
)

user_org_paris_nord_patricia.skip_confirmation!
user_org_paris_nord_patricia.save!
user_org_paris_nord_patricia.profile_for(org_paris_nord).update!(logement: 2)

user_org_paris_nord_josephine = User.new(
  first_name: "Joséphine",
  last_name: "Duroy",
  birth_date: Date.parse("01/03/2018"),
  responsible: user_org_paris_nord_patricia,
  organisation_ids: [org_paris_nord.id],
  created_through: "user_sign_up"
)
user_org_paris_nord_josephine.save!

user_org_paris_nord_lea = User.new(
  first_name: "Léa",
  last_name: "Dupont",
  email: "lea_dupont@demo.rdv-solidarites.fr",
  birth_date: Date.parse("01/12/1982"),
  password: "123456",
  phone_number: "0101010102",
  organisation_ids: [org_paris_nord.id],
  created_through: "user_sign_up"
)

user_org_paris_nord_lea.skip_confirmation!
user_org_paris_nord_lea.save!
user_org_paris_nord_lea.profile_for(org_paris_nord).update!(logement: 2)

user_org_paris_nord_jean = User.new(
  first_name: "Jean",
  last_name: "Moustache",
  email: "jean_moustache@demo.rdv-solidarites.fr",
  birth_date: Date.parse("10/01/1973"),
  password: "123456",
  phone_number: "0101010103",
  organisation_ids: [org_paris_nord.id, org_bapaume.id, org_arques.id],
  created_through: "user_sign_up"
)

user_org_paris_nord_jean.skip_confirmation!
user_org_paris_nord_jean.save!
user_org_paris_nord_jean.profile_for(org_paris_nord).update!(logement: 2)

# Insert a lot of users and add them to the paris_nord organisation
# rubocop:disable Rails/SkipsModelValidations
now = Time.zone.now
users_attributes = 10_000.times.map do |i|
  {
    created_at: now,
    updated_at: now,
    first_name: "first_name_#{i}",
    last_name: "last_name_#{i}",
    email: "email_#{i}@test.com",
    phone_number: (format "+336%08d", i),
    phone_number_formatted: (format "+336%08d", i),
    created_through: "user_sign_up",
  }
end
results = User.insert_all!(users_attributes, returning: Arel.sql("id")) # [{"id"=>1}, {"id"=>2}, ...]
user_ids = results.flat_map(&:values) # [1, 2, ...]
user_organisation_attributes = user_ids.map { |id| { user_id: id, organisation_id: org_paris_nord.id } }
UserProfile.insert_all!(user_organisation_attributes)
# rubocop:enable Rails/SkipsModelValidations

# AGENTS

agent_org_paris_nord_pmi_martine = Agent.new(
  email: "martine@demo.rdv-solidarites.fr",
  uid: "martine@demo.rdv-solidarites.fr",
  first_name: "Martine",
  last_name: "Validay",
  password: "123456",
  service_id: service_pmi.id,
  invitation_accepted_at: 10.days.ago,
  roles_attributes: [{ organisation: org_paris_nord, level: AgentRole::LEVEL_ADMIN }],
  agent_territorial_access_rights_attributes: [{
    territory: territory75,
    allow_to_manage_teams: true,
    allow_to_manage_access_rights: true,
    allow_to_invite_agents: true,
    allow_to_download_metrics: true,
  }]
)
agent_org_paris_nord_pmi_martine.skip_confirmation!
agent_org_paris_nord_pmi_martine.save!
agent_org_paris_nord_pmi_martine.territorial_roles.create!(territory: territory75)

agent_org_paris_nord_pmi_marco = Agent.new(
  email: "marco@demo.rdv-solidarites.fr",
  uid: "marco@demo.rdv-solidarites.fr",
  first_name: "Marco",
  last_name: "Durand",
  password: "123456",
  service_id: service_pmi.id,
  invitation_accepted_at: 10.days.ago,
  roles_attributes: [{ organisation: org_paris_nord, level: AgentRole::LEVEL_BASIC }],
  agent_territorial_access_rights_attributes: [{
    territory: territory75,
    allow_to_manage_teams: false,
    allow_to_manage_access_rights: false,
    allow_to_invite_agents: false,
    allow_to_download_metrics: false,
  }]
)
agent_org_paris_nord_pmi_marco.skip_confirmation!
agent_org_paris_nord_pmi_marco.save!

agent_org_paris_nord_social_polo = Agent.new(
  email: "polo@demo.rdv-solidarites.fr",
  uid: "polo@demo.rdv-solidarites.fr",
  first_name: "Polo",
  last_name: "Durant",
  password: "123456",
  service_id: service_social.id,
  invitation_accepted_at: 10.days.ago,
  roles_attributes: [{ organisation: org_paris_nord, level: AgentRole::LEVEL_BASIC }],
  agent_territorial_access_rights_attributes: [{
    territory: territory75,
    allow_to_manage_teams: false,
    allow_to_manage_access_rights: false,
    allow_to_invite_agents: false,
    allow_to_download_metrics: false,
  }]
)
agent_org_paris_nord_social_polo.skip_confirmation!
agent_org_paris_nord_social_polo.save!

org_arques_pmi_maya = Agent.new(
  email: "maya@demo.rdv-solidarites.fr",
  uid: "maya@demo.rdv-solidarites.fr",
  first_name: "Maya",
  last_name: "Patrick",
  password: "123456",
  service_id: service_pmi.id,
  invitation_accepted_at: 10.days.ago,
  roles_attributes: Organisation.where(territory: territory62).pluck(:id).map { { organisation_id: _1, level: AgentRole::LEVEL_ADMIN } },
  agent_territorial_access_rights_attributes: [{
    territory: territory62,
    allow_to_manage_teams: true,
    allow_to_manage_access_rights: true,
    allow_to_invite_agents: true,
    allow_to_download_metrics: true,
  }]
)
org_arques_pmi_maya.skip_confirmation!
org_arques_pmi_maya.save!

agent_org_bapaume_pmi_bruno = Agent.new(
  email: "bruno@demo.rdv-solidarites.fr",
  uid: "bruno@demo.rdv-solidarites.fr",
  first_name: "Bruno",
  last_name: "Frangi",
  password: "123456",
  service_id: service_pmi.id,
  invitation_accepted_at: 10.days.ago,
  roles_attributes: [{ organisation: org_bapaume, level: AgentRole::LEVEL_ADMIN }],
  agent_territorial_access_rights_attributes: [{
    territory: territory62,
    allow_to_manage_teams: false,
    allow_to_manage_access_rights: false,
    allow_to_invite_agents: false,
    allow_to_download_metrics: false,
  }]
)
agent_org_bapaume_pmi_bruno.skip_confirmation!
agent_org_bapaume_pmi_bruno.save!
AgentTerritorialRole.create!(agent: agent_org_bapaume_pmi_bruno, territory: territory62)

agent_org_bapaume_pmi_gina = Agent.new(
  email: "gina@demo.rdv-solidarites.fr",
  uid: "gina@demo.rdv-solidarites.fr",
  first_name: "Gina",
  last_name: "Leone",
  password: "123456",
  service_id: service_pmi.id,
  invitation_accepted_at: 10.days.ago,
  roles_attributes: [{ organisation: org_bapaume, level: AgentRole::LEVEL_ADMIN }],
  agent_territorial_access_rights_attributes: [{
    territory: territory62,
    allow_to_manage_teams: false,
    allow_to_manage_access_rights: false,
    allow_to_invite_agents: false,
    allow_to_download_metrics: false,
  }]
)
agent_org_bapaume_pmi_gina.skip_confirmation!
agent_org_bapaume_pmi_gina.save!

# Insert a lot of agents and add them to the paris_nord organisation
# rubocop:disable Rails/SkipsModelValidations
agents_attributes = 1_000.times.map do |i|
  {
    created_at: now,
    updated_at: now,
    first_name: "first_name_#{i}",
    last_name: "last_name_#{i}",
    email: "email_#{i}@test.com",
    uid: "email_#{i}@test.com",
    service_id: service_social.id,
  }
end
results = Agent.insert_all!(agents_attributes, returning: Arel.sql("id")) # [{"id"=>1}, {"id"=>2}, ...]
agent_ids = results.flat_map(&:values) # [1, 2, ...]
agent_role_attributes = agent_ids.map { |id| { agent_id: id, organisation_id: org_paris_nord.id } }
AgentRole.insert_all!(agent_role_attributes)

agent_territorial_access_rights_attributes = agent_ids.map { |id| { agent_id: id, territory_id: territory75.id, created_at: Time.zone.now, updated_at: Time.zone.now } }
AgentTerritorialAccessRight.insert_all!(agent_territorial_access_rights_attributes)
# rubocop:enable Rails/SkipsModelValidations

# SECTOR ATTRIBUTIONS - AGENT LEVEL

SectorAttribution.create!(
  sector: sector_bapaume_nord,
  organisation: org_bapaume,
  agent: agent_org_bapaume_pmi_bruno,
  level: SectorAttribution::LEVEL_AGENT
)

SectorAttribution.create!(
  sector: sector_bapaume_sud,
  organisation: org_bapaume,
  agent: agent_org_bapaume_pmi_gina,
  level: SectorAttribution::LEVEL_AGENT
)

# PLAGES OUVERTURES

_plage_ouverture_org_paris_nord_martine_classique = PlageOuverture.create!(
  title: "Permanence classique",
  organisation_id: org_paris_nord.id,
  agent_id: agent_org_paris_nord_pmi_martine.id,
  lieu_id: lieu_org_paris_nord_bolivar.id,
  motif_ids: [motif_org_paris_nord_pmi_rappel.id, motif_org_paris_nord_pmi_gyneco.id, motif_org_paris_nord_pmi_prenatale.id, motif_org_paris_nord_pmi_suivi.id, motif_org_paris_nord_pmi_securite.id],
  first_day: Date.tomorrow,
  start_time: Tod::TimeOfDay.new(8),
  end_time: Tod::TimeOfDay.new(12),
  recurrence: Montrose.every(:week, day: [1, 2, 3, 4, 5], interval: 1, starts: Date.tomorrow, on: %i[monday tuesday thursday friday])
)
_plage_ouverture_org_paris_nord_martine_telephonique = PlageOuverture.create!(
  title: "Permanence téléphonique",
  organisation_id: org_paris_nord.id,
  agent_id: agent_org_paris_nord_pmi_martine.id,
  lieu_id: nil,
  motif_ids: [motif_org_paris_nord_pmi_rappel.id],
  first_day: Date.tomorrow,
  start_time: Tod::TimeOfDay.new(12),
  end_time: Tod::TimeOfDay.new(14),
  recurrence: Montrose.every(:week, day: [1, 2, 3, 4, 5], interval: 1, starts: Date.tomorrow, on: %i[monday tuesday thursday friday])
)
_plage_ouverture_org_paris_nord_martine_mercredi = PlageOuverture.create!(
  title: "Permanence enfant",
  organisation_id: org_paris_nord.id,
  agent_id: agent_org_paris_nord_pmi_martine.id,
  lieu_id: lieu_org_paris_nord_bolivar.id,
  motif_ids: [motif_org_paris_nord_pmi_rappel.id, motif_org_paris_nord_pmi_prenatale.id, motif_org_paris_nord_pmi_suivi.id, motif_org_paris_nord_pmi_securite.id],
  first_day: Date.tomorrow,
  start_time: Tod::TimeOfDay.new(8),
  end_time: Tod::TimeOfDay.new(12),
  recurrence: Montrose.every(:week, on: [:wednesday], interval: 1, starts: Date.tomorrow)
)
_plage_ouverture_org_paris_nord_martine_exceptionnelle = PlageOuverture.create!(
  title: "Aprem PMI exptn",
  organisation_id: org_paris_nord.id,
  agent_id: agent_org_paris_nord_pmi_martine.id,
  lieu_id: lieu_org_paris_nord_bolivar.id,
  motif_ids: [motif_org_paris_nord_pmi_rappel.id, motif_org_paris_nord_pmi_prenatale.id, motif_org_paris_nord_pmi_suivi.id, motif_org_paris_nord_pmi_securite.id],
  first_day: Date.tomorrow,
  start_time: Tod::TimeOfDay.new(14),
  end_time: Tod::TimeOfDay.new(18)
)
_plage_ouverture_org_paris_nord_marco_perm = PlageOuverture.create!(
  title: "Perm.",
  organisation_id: org_paris_nord.id,
  agent_id: agent_org_paris_nord_pmi_marco.id,
  lieu_id: lieu_org_paris_nord_bd_aubervilliers.id,
  motif_ids: [motif_org_paris_nord_pmi_rappel.id, motif_org_paris_nord_pmi_gyneco.id, motif_org_paris_nord_pmi_prenatale.id, motif_org_paris_nord_pmi_suivi.id, motif_org_paris_nord_pmi_securite.id,
              motif_org_paris_nord_pmi_prenatale_phone.id,],
  first_day: Date.tomorrow,
  start_time: Tod::TimeOfDay.new(14),
  end_time: Tod::TimeOfDay.new(16),
  recurrence: Montrose.every(:week, on: [:tuesday], interval: 1, starts: Date.tomorrow)
)
_plage_ouverture_org_arques_maya_tradi = PlageOuverture.create!(
  title: "Perm. tradi",
  organisation_id: org_arques.id,
  agent_id: org_arques_pmi_maya.id,
  lieu_id: lieu_arques_nord.id,
  motif_ids: [motifs[:arques][:pmi_rappel].id, motifs[:arques][:pmi_prenatale].id],
  first_day: Date.tomorrow,
  start_time: Tod::TimeOfDay.new(9),
  end_time: Tod::TimeOfDay.new(15),
  recurrence: Montrose.every(:week, interval: 1, starts: Date.tomorrow)
)
_plage_ouverture_org_bapaume_bruno_classique = PlageOuverture.create!(
  title: "Perm. classique",
  organisation_id: org_bapaume.id,
  agent_id: agent_org_bapaume_pmi_bruno.id,
  lieu_id: lieu_bapaume_est.id,
  motif_ids: [motifs[:bapaume][:pmi_rappel].id, motifs[:bapaume][:pmi_prenatale].id],
  first_day: Date.tomorrow,
  start_time: Tod::TimeOfDay.new(9),
  end_time: Tod::TimeOfDay.new(15),
  recurrence: Montrose.every(:week, interval: 1, starts: Date.tomorrow)
)

[1, 2, 4, 5].each do |weekday|
  PlageOuverture.create!(
    title: "Permamence jour #{weekday}",
    organisation_id: org_bapaume.id,
    agent_id: agent_org_bapaume_pmi_gina.id,
    lieu_id: lieu_bapaume_est.id,
    motif_ids: [motifs[:bapaume][:pmi_prenatale].id],
    first_day: Date.tomorrow,
    start_time: Tod::TimeOfDay.new(11),
    end_time: Tod::TimeOfDay.new(18),
    recurrence: Montrose.every(:week, interval: 1, starts: Date.tomorrow, day: [weekday])
  )
end

# RDVs

Rdv.create!(
  starts_at: Time.zone.today + 3.days + 10.hours,
  duration_in_min: 30,
  motif_id: motif_org_paris_nord_pmi_rappel.id,
  lieu: lieu_org_paris_nord_bolivar,
  organisation_id: org_paris_nord.id,
  agent_ids: [agent_org_paris_nord_pmi_martine.id],
  user_ids: [user_org_paris_nord_patricia.id],
  context: "Visite de courtoisie"
)
Rdv.create!(
  starts_at: Time.zone.today + 4.days + 15.hours,
  duration_in_min: 30,
  motif_id: motif_org_paris_nord_pmi_suivi.id,
  lieu: lieu_org_paris_nord_bd_aubervilliers,
  organisation_id: org_paris_nord.id,
  agent_ids: [agent_org_paris_nord_pmi_martine.id],
  user_ids: [user_org_paris_nord_josephine.id],
  context: "Suivi vaccins"
)
Rdv.create!(
  starts_at: Time.zone.today + 5.days + 11.hours,
  duration_in_min: 30,
  motif_id: motif_org_paris_nord_pmi_securite.id,
  lieu: lieu_org_paris_nord_bd_aubervilliers,
  organisation_id: org_paris_nord.id,
  agent_ids: [agent_org_paris_nord_pmi_martine.id],
  user_ids: [user_org_paris_nord_josephine.id],
  context: "Visite à domicile"
)

Rdv.create!(
  starts_at: Time.zone.today + 5.days + 11.hours,
  duration_in_min: 30,
  motif_id: motif_org_paris_nord_pmi_securite.id,
  lieu: lieu_org_paris_nord_bd_aubervilliers,
  organisation_id: org_paris_nord.id,
  agent_ids: [agent_org_paris_nord_pmi_martine.id],
  user_ids: [user_org_paris_nord_josephine.id],
  context: "Visite à domicile"
)

10.times do |i|
  Rdv.create!(
    starts_at: Time.zone.today + 17.hours + i.weeks,
    duration_in_min: 60,
    motif_id: motif_org_paris_nord_pmi_collectif.id,
    lieu: lieu_org_paris_nord_bd_aubervilliers,
    organisation_id: org_paris_nord.id,
    agent_ids: [agent_org_paris_nord_pmi_marco.id],
    users_count: 0,
    user_ids: []
  )

  Rdv.create!(
    starts_at: Time.zone.today + 2.days + 16.hours + i.weeks,
    duration_in_min: 60,
    motif_id: motif_org_paris_nord_pmi_collectif.id,
    lieu: lieu_org_paris_nord_bolivar,
    organisation_id: org_paris_nord.id,
    agent_ids: [agent_org_paris_nord_social_polo.id],
    users_count: 0,
    user_ids: []
  )
end

# Insert a lot of rdvs in the past 2 years
# rubocop:disable Rails/SkipsModelValidations
rdv_attributes = 1000.times.flat_map do |i|
  day = 2.years.ago.beginning_of_day + i.days
  (9..16).map do |hour|
    {
      created_at: now,
      updated_at: now,
      starts_at: day + hour.hours,
      ends_at: day + hour.hours + 30.minutes,
      motif_id: motif_org_paris_nord_pmi_securite.id,
      lieu_id: lieu_org_paris_nord_bd_aubervilliers.id,
      organisation_id: org_paris_nord.id,
      context: "Context #{day} #{hour}",
    }
  end
end
results = Rdv.insert_all!(rdv_attributes, returning: Arel.sql("id")) # [{"id"=>1}, {"id"=>2}, ...]
rdv_ids = results.flat_map(&:values) # [1, 2, ...]
agent_rdv_attributes = rdv_ids.map { |id| { agent_id: agent_org_paris_nord_pmi_martine.id, rdv_id: id } }
AgentsRdv.insert_all!(agent_rdv_attributes)
rdv_user_attributes = rdv_ids.map { |id| { user_id: user_org_paris_nord_josephine.id, rdv_id: id, send_lifecycle_notifications: true, send_reminder_notification: true } }
RdvsUser.insert_all!(rdv_user_attributes)
events = %w[new_creneau_available rdv_cancelled rdv_created rdv_date_updated rdv_upcoming_reminder]
receipts_attributes = rdv_ids.map { |id| { rdv_id: id, event: events.sample, channel: Receipt.channels.values.sample, result: Receipt.results.values.sample, created_at: now, updated_at: now } }
Receipt.insert_all!(receipts_attributes)
# rubocop:enable Rails/SkipsModelValidations

# Sync rdv counter cache
unknown_rdv_count_by_agent = Rdv.status("unknown_past").joins(:agents_rdvs).group("agents_rdvs.agent_id").count
unknown_rdv_count_by_agent.each do |agent_id, unknown_past_rdv_count|
  Agent.where(id: agent_id).update_all(unknown_past_rdv_count: unknown_past_rdv_count) # rubocop:disable Rails/SkipsModelValidations
end

Absence.create!(
  title: "Formation",
  agent: agent_org_paris_nord_pmi_martine,
  first_day: 1.week.from_now,
  start_time: Tod::TimeOfDay.new(8),
  end_time: Tod::TimeOfDay.new(18)
)
