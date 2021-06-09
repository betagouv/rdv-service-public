# frozen_string_literal: true

require "csv"

# TODO: when trying to create models using direct associations like
# `organisation: org_paris_nord` instead of `organisation_id: org_paris_nord.id`
# CircleCI throws ActiveRecord::AssociationTypeMismatch that seems to indicate
# that the model files are loaded twice, or something related to HABTM
# associations..

# TERRITORIEs

territory75 = Territory.create!(
  departement_number: "75",
  name: "Paris",
  sms_provider: "netsize",
  sms_configuration: { api_url: "an_url", user_pwd: "pwd" }
)
territory62 = Territory.create!(
  departement_number: "62",
  name: "Pas-de-Calais",
  sms_provider: "netsize",
  sms_configuration: { api_url: "an_url", user_pwd: "pwd" }
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
  { human_id: "1055", name: "MDS St Pol sur Ternoise" }
].map do |attributes|
  organisation = Organisation.create!(phone_number: "0123456789", territory: territory62, human_id: attributes[:human_id], name: attributes[:name])
  sector = Sector.create!(name: "Secteur de #{attributes[:name][4..]}", human_id: attributes[:human_id], territory: territory62)
  sector.attributions.create!(organisation: organisation, level: SectorAttribution::LEVEL_ORGANISATION)
  [attributes[:human_id], { organisation: organisation, sector: sector }]
end.to_h

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
_service_secretariat = Service.create!(name: "Secrétariat", short_name: "Secrétariat")
_service_nouveau = Service.create!(name: "Médico-social", short_name: "Médico-social")

# SERVICE LIBELLES

libelle_pmi_rappel = MotifLibelle.create!(service: service_pmi, name: "Être rappelé par la PMI")
libelle_pmi_prenatale = MotifLibelle.create!(service: service_pmi, name: "Consultation prénatale")
libelle_pmi_gyneco = MotifLibelle.create!(service: service_pmi, name: "Consultation gynécologie / contraception")
libelle_pmi_suivi = MotifLibelle.create!(service: service_pmi, name: "Suivi après naissance")
libelle_pmi_securite = MotifLibelle.create!(service: service_pmi, name: "Sécurité du domicile")
libelle_pmi_collectif = MotifLibelle.create!(service: service_pmi, name: "RDV Collectif")
libelle_social_rappel = MotifLibelle.create!(service: service_social, name: "Être rappelé par la MDS")
libelle_social_suivi = MotifLibelle.create!(service: service_social, name: "Suivi RSA")
libelle_social_droits = MotifLibelle.create!(service: service_social, name: "Droits sociaux")
libelle_social_collectif = MotifLibelle.create!(service: service_social, name: "RDV Collectif")

# MOTIFS org_paris_nord

motif_org_paris_nord_pmi_rappel = Motif.create!(
  name: libelle_pmi_rappel.name,
  color: "#FF7C00",
  organisation_id: org_paris_nord.id,
  service_id: service_pmi.id,
  reservable_online: true,
  location_type: :phone
)
motif_org_paris_nord_pmi_gyneco = Motif.create!(
  name: libelle_pmi_gyneco.name,
  color: "#FF7C00",
  organisation_id: org_paris_nord.id,
  service_id: service_pmi.id,
  reservable_online: false,
  location_type: :phone
)
motif_org_paris_nord_pmi_prenatale = Motif.create!(
  name: libelle_pmi_prenatale.name,
  color: "#CC7C00",
  organisation_id: org_paris_nord.id,
  service_id: service_pmi.id,
  reservable_online: true,
  location_type: :public_office
)
motif_org_paris_nord_pmi_prenatale_phone = Motif.create!(
  name: libelle_pmi_prenatale.name,
  color: "#CC7C00",
  organisation_id: org_paris_nord.id,
  service_id: service_pmi.id,
  reservable_online: true,
  location_type: :phone
)
motif_org_paris_nord_pmi_suivi = Motif.create!(
  name: libelle_pmi_suivi.name,
  color: "#00FC60",
  organisation_id: org_paris_nord.id,
  service_id: service_pmi.id,
  reservable_online: true,
  location_type: :public_office,
  follow_up: true
)
motif_org_paris_nord_pmi_securite = Motif.create!(
  name: libelle_pmi_securite.name,
  color: "#1010FF",
  organisation_id: org_paris_nord.id,
  service_id: service_pmi.id,
  reservable_online: true,
  location_type: :home
)
_motif_org_paris_nord_pmi_collectif = Motif.create!(
  name: libelle_pmi_collectif.name,
  color: "#1049F3",
  organisation_id: org_paris_nord.id,
  service_id: service_pmi.id,
  reservable_online: true,
  location_type: :public_office
)
_motif_org_paris_nord_social_rappel = Motif.create!(
  name: libelle_social_rappel.name,
  color: "#FF7C00",
  organisation_id: org_paris_nord.id,
  service_id: service_social.id,
  reservable_online: true,
  location_type: :phone
)
_motif_org_paris_nord_social_suivi = Motif.create!(
  name: libelle_social_suivi.name,
  color: "#CC7C00",
  organisation_id: org_paris_nord.id,
  service_id: service_social.id,
  reservable_online: true,
  location_type: :public_office,
  follow_up: true
)
_motif_org_paris_nord_social_droits = Motif.create!(
  name: libelle_social_droits.name,
  color: "#00FC60",
  organisation_id: org_paris_nord.id,
  service_id: service_social.id,
  reservable_online: true,
  location_type: :public_office
)
_motif_org_paris_nord_social_collectif = Motif.create!(
  name: libelle_social_collectif.name,
  color: "#113C65",
  organisation_id: org_paris_nord.id,
  service_id: service_social.id,
  reservable_online: true,
  location_type: :public_office
)

# MOTIFS organisations du 62

motifs = {}
[[:bapaume, org_bapaume], [:arques, org_arques]].each do |seed_id, org|
  motifs[seed_id] ||= {}
  motifs[seed_id][:pmi_rappel] = Motif.create!(
    name: libelle_pmi_rappel.name,
    color: "#10FF10",
    organisation_id: org.id,
    service_id: service_pmi.id,
    reservable_online: true,
    location_type: :phone
  )
  motifs[seed_id][:pmi_prenatale] = Motif.create!(
    name: libelle_pmi_prenatale.name,
    color: "#FF1010",
    organisation_id: org.id,
    service_id: service_pmi.id,
    reservable_online: true,
    location_type: :public_office
  )
end

# LIEUX

lieu_org_paris_nord_bolivar = Lieu.create!(
  name: "MDS Bolivar",
  organisation: org_paris_nord,
  address: "126 Avenue Simon Bolivar, 75019, Paris",
  latitude: 48.8809263,
  longitude: 2.3739077
)
lieu_org_paris_nord_bd_aubervilliers = Lieu.create!(
  name: "MDS Bd Aubervilliers",
  organisation: org_paris_nord,
  address: "18 Boulevard d'Aubervilliers, 75019 Paris",
  latitude: 48.8882196,
  longitude: 2.3650464
)
lieu_arques_nord = Lieu.create!(
  name: "Maison Arques Nord",
  organisation: org_arques,
  address: "10 rue du marechal leclerc, 62410 Arques",
  latitude: 50.7406,
  longitude: 2.3103
)
lieu_bapaume_est = Lieu.create!(
  name: "MJC Bapaume Est",
  organisation: org_bapaume,
  address: "10 rue emile delot, 62450 Arques",
  latitude: 50.1026,
  longitude: 2.8486
)

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
  organisation_ids: [org_paris_nord.id],
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
  organisation_ids: [org_paris_nord.id],
  created_through: "user_sign_up"
)

user_org_paris_nord_jean.skip_confirmation!
user_org_paris_nord_jean.save!
user_org_paris_nord_jean.profile_for(org_paris_nord).update!(logement: 2)

# AGENTS

agent_org_paris_nord_pmi_martine = Agent.new(
  email: "martine@demo.rdv-solidarites.fr",
  uid: "martine@demo.rdv-solidarites.fr",
  first_name: "Martine",
  last_name: "Validay",
  password: "123456",
  service_id: service_pmi.id,
  invitation_accepted_at: 10.days.ago,
  roles_attributes: [{ organisation: org_paris_nord, level: AgentRole::LEVEL_ADMIN }]
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
  roles_attributes: [{ organisation: org_paris_nord, level: AgentRole::LEVEL_BASIC }]
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
  roles_attributes: [{ organisation: org_paris_nord, level: AgentRole::LEVEL_BASIC }]
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
  roles_attributes: Organisation.where(territory: territory62).pluck(:id).map { { organisation_id: _1, level: AgentRole::LEVEL_ADMIN } }
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
  roles_attributes: [{ organisation: org_bapaume, level: AgentRole::LEVEL_ADMIN }]
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
  roles_attributes: [{ organisation: org_bapaume, level: AgentRole::LEVEL_ADMIN }]
)
agent_org_bapaume_pmi_gina.skip_confirmation!
agent_org_bapaume_pmi_gina.save!

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
              motif_org_paris_nord_pmi_prenatale_phone.id],
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
_plage_ouverture_org_bapaume_gina_classique = PlageOuverture.create!(
  title: "Perm. prenatale",
  organisation_id: org_bapaume.id,
  agent_id: agent_org_bapaume_pmi_gina.id,
  lieu_id: lieu_bapaume_est.id,
  motif_ids: [motifs[:bapaume][:pmi_prenatale].id],
  first_day: Date.tomorrow,
  start_time: Tod::TimeOfDay.new(11),
  end_time: Tod::TimeOfDay.new(18),
  recurrence: Montrose.every(:week, interval: 1, starts: Date.tomorrow)
)

# RDVs

Rdv.create!(
  duration_in_min: 30,
  starts_at: Time.zone.today + 3.days + 10.hours,
  motif_id: motif_org_paris_nord_pmi_rappel.id,
  lieu: lieu_org_paris_nord_bolivar,
  organisation_id: org_paris_nord.id,
  agent_ids: [agent_org_paris_nord_pmi_martine.id],
  user_ids: [user_org_paris_nord_patricia.id],
  context: "Visite de courtoisie"
)
Rdv.create(
  duration_in_min: 30,
  starts_at: Time.zone.today + 4.days + 15.hours,
  motif_id: motif_org_paris_nord_pmi_suivi.id,
  lieu: lieu_org_paris_nord_bd_aubervilliers,
  organisation_id: org_paris_nord.id,
  agent_ids: [agent_org_paris_nord_pmi_martine.id],
  user_ids: [user_org_paris_nord_josephine.id],
  context: "Suivi vaccins"
)

# User Notes

UserNote.create!(
  user: user_org_paris_nord_patricia,
  organisation: org_paris_nord,
  agent: agent_org_paris_nord_pmi_martine,
  text: "sympathique et joviale"
)
