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

org_paris_nord = Organisation.create!(
  name: "MDS Paris Nord",
  phone_number: "0123456789",
  territory: territory75
)

org_paris_sud = Organisation.create!(
  name: "MDS Paris Sud",
  phone_number: "0123456789",
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
  organisation = Organisation.create!(phone_number: "0123456789", territory: territory62, name: attributes[:name])
  sector = Sector.create!(name: "Secteur de #{attributes[:name][4..]}", human_id: attributes[:human_id], territory: territory62)
  sector.attributions.create!(organisation: organisation, level: SectorAttribution::LEVEL_ORGANISATION)
  [attributes[:human_id], { organisation: organisation, sector: sector }]
end

# Bapaume is created without the organisation-level attribution
org_bapaume = Organisation.create!(phone_number: "0123456789", territory: territory62, name: "MDS Bapaume")
sector_bapaume_nord = Sector.create!(name: "Bapaume Nord", human_id: "1034-nord", territory: territory62)
sector_bapaume_sud = Sector.create!(name: "Bapaume Sud", human_id: "1034-sud", territory: territory62)
sector_bapaume_fallback = Sector.create!(name: "Bapaume Entier", human_id: "1034-fallback", territory: territory62)
sector_bapaume_fallback.attributions.create!(organisation: org_bapaume, level: SectorAttribution::LEVEL_ORGANISATION)
human_id_map["1034-nord"] = { organisation: org_bapaume, sector: sector_bapaume_nord }
human_id_map["1034-sud"] = { organisation: org_bapaume, sector: sector_bapaume_sud }
human_id_map["1034-fallback"] = { organisation: org_bapaume, sector: sector_bapaume_fallback }
org_arques = human_id_map["1030"][:organisation]

# SERVICES

service_pmi = Service.create!(name: "Protection Maternelle Infantile", short_name: "PMI")
service_social = Service.create!(name: "Service social", short_name: "Service Social")
service_secretariat = Service.create!(name: Service::SECRETARIAT, short_name: "Secrétariat")
territory62.services << [service_pmi, service_social, service_secretariat]
territory75.services << [service_pmi, service_social, service_secretariat]

# MOTIFS org_paris_nord

motif_org_paris_nord_pmi_rappel = Motif.create!(
  name: "Être rappelé par la PMI",
  organisation_id: org_paris_nord.id,
  service_id: service_pmi.id,
  bookable_by: :everyone,
  location_type: :phone
)
motif_org_paris_nord_pmi_gyneco = Motif.create!(
  name: "Consultation gynécologie / contraception",
  organisation_id: org_paris_nord.id,
  service_id: service_pmi.id,
  bookable_by: :agents,
  location_type: :phone
)
motif_org_paris_nord_pmi_prenatale = Motif.create!(
  name: "Consultation prénatale",
  organisation_id: org_paris_nord.id,
  service_id: service_pmi.id,
  bookable_by: :everyone,
  location_type: :public_office
)
motif_org_paris_nord_pmi_prenatale_phone = Motif.create!(
  name: "Consultation prénatale",
  organisation_id: org_paris_nord.id,
  service_id: service_pmi.id,
  bookable_by: :everyone,
  location_type: :phone
)
motif_org_paris_nord_pmi_suivi = Motif.create!(
  name: "Suivi après naissance",
  organisation_id: org_paris_nord.id,
  service_id: service_pmi.id,
  bookable_by: :everyone,
  location_type: :public_office,
  follow_up: true
)
motif_org_paris_nord_pmi_securite = Motif.create!(
  name: "Sécurité du domicile",
  organisation_id: org_paris_nord.id,
  service_id: service_pmi.id,
  bookable_by: :everyone,
  location_type: :home
)
motif_org_paris_nord_pmi_collectif = Motif.create!(
  name: "Atelier Collectif",
  organisation_id: org_paris_nord.id,
  service_id: service_pmi.id,
  collectif: true,
  bookable_by: :everyone,
  default_duration_in_min: 60,
  location_type: :public_office
)
motif_org_paris_nord_social_rappel = Motif.create!(
  name: "Être rappelé par la MDS",
  organisation_id: org_paris_nord.id,
  service_id: service_social.id,
  bookable_by: :everyone,
  location_type: :phone
)
motif_org_paris_nord_social_suivi = Motif.create!(
  name: "Suivi RSA",
  organisation_id: org_paris_nord.id,
  service_id: service_social.id,
  bookable_by: :everyone,
  location_type: :public_office,
  follow_up: true
)
_motif_org_paris_nord_social_droits = Motif.create!(
  name: "Droits sociaux",
  organisation_id: org_paris_nord.id,
  service_id: service_social.id,
  bookable_by: :agents,
  location_type: :public_office
)
_motif_org_paris_nord_social_collectif = Motif.create!(
  name: "Forum",
  organisation_id: org_paris_nord.id,
  service_id: service_social.id,
  collectif: true,
  bookable_by: :everyone,
  default_duration_in_min: 120,
  location_type: :public_office
)

# MOTIFS organisations du 62

motifs = {}
Organisation.where(territory: territory62).each do |org|
  motifs[org] ||= {}
  motifs[org][:pmi_rappel] = Motif.create!(
    name: "Être rappelé par la PMI",
    organisation_id: org.id,
    service_id: service_pmi.id,
    bookable_by: :everyone,
    location_type: :phone,
    restriction_for_rdv: "Merci d’apporter les documents nécessaires"
  )
  motifs[org][:pmi_prenatale] = Motif.create!(
    name: "Consultation prénatale",
    organisation_id: org.id,
    service_id: service_pmi.id,
    bookable_by: :everyone,
    location_type: :public_office,
    restriction_for_rdv: "Merci d’apporter les documents nécessaires"
  )
end

now = Time.zone.now
motifs_attributes = 1000.times.map do |i|
  {
    created_at: now,
    updated_at: now,
    name: "motif_#{i}",
    color: Motif::DSFR_ILLUSTRATION_COLORS.sample,
    organisation_id: org_arques.id,
    service_id: service_pmi.id,
    bookable_by: :everyone,
    location_type: :public_office,
    public_link_id: SecureRandom.base58(8),
  }
end
Motif.insert_all!(motifs_attributes) # rubocop:disable Rails/SkipsModelValidations

# LIEUX

lieu_org_paris_nord_bolivar = Lieu.create!(
  name: "MDS Bolivar",
  organisation: org_paris_nord,
  availability: :enabled,
  address: "126 Avenue Simon Bolivar, Paris, 75019",
  latitude: 48.8809263,
  longitude: 2.3739077
)
lieu_org_paris_nord_bd_aubervilliers = Lieu.create!(
  name: "MDS Bd Aubervilliers",
  organisation: org_paris_nord,
  availability: :enabled,
  address: "18 Boulevard d'Aubervilliers, Paris, 75019",
  latitude: 48.8882196,
  longitude: 2.3650464
)
lieu_arques_nord = Lieu.create!(
  name: "Maison Arques Nord",
  organisation: org_arques,
  availability: :enabled,
  address: "10 rue du marechal leclerc, Arques, 62410",
  latitude: 50.7406,
  longitude: 2.3103
)
lieu_bapaume_est = Lieu.create!(
  name: "MJC Bapaume Est",
  organisation: org_bapaume,
  availability: :enabled,
  address: "10 rue emile delot, Arques, 62450",
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

# Prénoms et noms générés avec la gem Faker (locale fr) et complétés à la main pour refléter la
# diversité des origines des noms en France, puis figés pour garder des seeds déterministes.
# Les emails sont dérivés du nom (<initiale><nom>@<acronyme_du_service>.rdv.fr) : le domaine .rdv.fr
# n'existe pas, ce qui évite tout envoi accidentel de mail depuis une base de démo.
noms_usagers = <<~NOMS.split("\n").map { _1.split("|").map(&:strip) }
  Virginie|Le Roux
  Ruth|Lacroix
  Thomas|Antoine
  Karim|Benali
  Louis|Bouvier
  Marianne|Dumas
  Ronan|Meunier
  Yasmine|El Amrani
  Marjorie|Colin
  Cyrielle|Moreau
  Lauriane|Masson
  Mehdi|Chérif
  Jade|Lucas
  Arielle|Denis
  Philippe|Andre
  Sarah|Bensoussan
  Jocelyne|Monnier
  Christelle|Robin
  Florent|Jacquet
  Nadia|Haddad
  Esther|Brunet
  Eugénie|Guillot
  Daniel|Carpentier
  Rachida|Meddour
  Émile|Renault
  Zoé|Fernandez
  Vivien|Lefèvre
  Aminata|Diallo
  Serge|Rey
  Manon|Tessier
  Guy|Leblanc
  Moussa|Traoré
  Cécile|Blanc
  Agathe|Marie
  Ludivine|Faure
  Fatou|Ndiaye
  Soline|Bouchet
  Adeline|Girard
  Charles|Schmitt
  Awa|Sarr
  Rose|Andre
  Gérard|André
  Jeanne|Rémy
  Ismaël|Camara
  Moïse|Bernard
  Adèle|Thomas
  Florence|Lévêque
  Emre|Yilmaz
  Gabin|Leger
  Arian|Schneider
  Geneviève|Gautier
  Elif|Demir
  Yvonne|Renaud
  Bertrand|Durand
  Sandrine|Dubois
  Mariana|Ferreira
  Rachel|Bertin
  Tiphaine|Méunier
  Alix|Lemaire
  Gonçalo|Pereira
  Caroline|Dupont
  Laureline|Maillard
  Annette|Martinez
  Sofia|Almeida
  Dominique|Mallet
  Léonie|Moulin
  Robert|Rolland
  Giulia|Rossi
  Chloé|Klein
  Blandine|Dumont
  Justine|Laurent
  Marco|Colombo
  Céleste|Olivier
  Armelle|Pichon
  Yvette|Boucher
  Chiara|Bianchi
  Irène|Lambert
  Béatrice|Michel
  Armeline|Laporte
  Camila|Rodriguez
  Ernest|Perrier
  Roger|Da Silva
  Laure|Menard
  Diego|Hernandez
  Basile|Clément
  Véronique|Philippe
  Mélodie|Fabre
  Wei|Nguyen
  Corinne|Henry
  Jérémie|Fournier
  Amandine|Francois
  Linh|Pham
  Gwendoline|Weber
  Claude|Mercier
  Émeric|Robert
  Mei|Chen
  Gaspard|Bonnet
  Fabrice|Marchal
  Cédric|David
  Anna|Kowalska
  Henriette|Noël
  Paule|Lejeune
  Emmanuel|Guérin
  Marek|Nowak
  Armand|Barre
  Isaac|Adam
  Maximilien|Clement
  Marie-Claire|Petit
  Bernard|Chauvin
  Alphonse|Hamon
  Mélanie|Martin
  Jean-Baptiste|Roche
  Stéphanie|Paris
  Bérangère|Benoit
  Gabriel|Deschamps
  Anne-Sophie|Vidal
  Gwenaëlle|Roux
  Arsène|Gaillard
  Benoît|Jean
  Paul-Henri|Marchand
  Thierry|Hubert
  Agnès|Lemoine
  Mireille|Gerard
  Laura|Martin-Bernard
  Maxime|Legrand
  Iris|Poirier
  Laurence|Besson
  Aymeric|Vincent
  Doriane|Collet
  Raphaëlle|Leveque
  Alain|Morel
  Frédéric|Marchand
  Adélaïde|Laine
NOMS

user_org_paris_nord_patricia = User.new(
  first_name: "Patricia",
  last_name: "Duroy",
  email: "pduroy@pmi.rdv.fr",
  birth_date: Date.parse("20/06/1975"),
  phone_number: "0101010101",
  organisation_ids: [org_paris_nord.id, org_arques.id],
  created_through: "user_sign_up",
  latest_login_at: Time.zone.now
)

user_org_paris_nord_patricia.save!
user_org_paris_nord_patricia.update!(logement: 2)

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
  email: "ldupont@pmi.rdv.fr",
  birth_date: Date.parse("01/12/1982"),
  phone_number: "0101010102",
  organisation_ids: [org_paris_nord.id],
  created_through: "user_sign_up",
  latest_login_at: Time.zone.now
)

user_org_paris_nord_lea.save!
user_org_paris_nord_lea.update!(logement: 2)

user_org_paris_nord_jean = User.new(
  first_name: "Jean",
  last_name: "Chevalier",
  email: "jchevalier@pmi.rdv.fr",
  birth_date: Date.parse("10/01/1973"),
  phone_number: "0101010103",
  organisation_ids: [org_paris_nord.id, org_bapaume.id, org_arques.id],
  created_through: "user_sign_up",
  latest_login_at: Time.zone.now
)

user_org_paris_nord_jean.save!
user_org_paris_nord_jean.update!(logement: 2)

user_org_paris_sud = User.new(
  first_name: "Francis",
  last_name: "Factice",
  email: "francis.factice@rdv.fr",
  birth_date: Date.parse("10/01/1973"),
  phone_number: "0101010103",
  organisation_ids: [org_paris_sud.id],
  created_through: "user_sign_up",
  latest_login_at: Time.zone.now
)

user_org_paris_sud.save!
user_org_paris_sud.update!(logement: 2)

user_org_arques = User.new(
  first_name: "Francis",
  last_name: "Factice",
  phone_number: "0611223344",
  organisation_ids: [org_arques.id],
  created_through: "user_sign_up",
  latest_login_at: Time.zone.now
)

user_org_arques.save!

user_org_bapaume = User.new(
  first_name: "François",
  last_name: "Factice",
  email: "francois.factice@rdv.fr",
  organisation_ids: [org_bapaume.id],
  created_through: "user_sign_up",
  latest_login_at: Time.zone.now
)

user_org_bapaume.save!

# Insert a lot of users and add them to the paris_nord organisation
# rubocop:disable Rails/SkipsModelValidations
now = Time.zone.now
users_attributes = 10_000.times.map do |i|
  prenom, nom = noms_usagers[i % noms_usagers.size]
  {
    created_at: now,
    updated_at: now,
    first_name: prenom,
    last_name: nom,
    email: "#{prenom[0]}#{nom}".parameterize.tr("-", "") + "#{i}@pmi.rdv.fr",
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
  email: "mvaliday@pmi.rdv.fr",
  uid: "mvaliday@pmi.rdv.fr",
  first_name: "Martine",
  last_name: "Validay",
  password: ENV["DB_SEEDS_USERS_AND_AGENTS_PASSWORD"],
  services: [service_pmi],
  invitation_accepted_at: 10.days.ago,
  roles_attributes: [{ organisation: org_paris_nord, access_level: AgentRole::ACCESS_LEVEL_ADMIN }],
  agent_territorial_access_rights_attributes: [{
    territory: territory75,
    allow_to_manage_teams: true,
    allow_to_manage_access_rights: true,
    allow_to_invite_agents: true,
  }]
)
agent_org_paris_nord_pmi_martine.skip_confirmation!
agent_org_paris_nord_pmi_martine.save!
agent_org_paris_nord_pmi_martine.territorial_roles.create!(territory: territory75)

agent_org_paris_nord_pmi_marco = Agent.new(
  email: "mdurand@pmi.rdv.fr",
  uid: "mdurand@pmi.rdv.fr",
  first_name: "Marco",
  last_name: "Durand",
  password: ENV["DB_SEEDS_USERS_AND_AGENTS_PASSWORD"],
  services: [service_pmi],
  invitation_accepted_at: 10.days.ago,
  last_sign_in_at: 2.days.ago,
  roles_attributes: [{ organisation: org_paris_nord, access_level: AgentRole::ACCESS_LEVEL_BASIC }],
  agent_territorial_access_rights_attributes: [{
    territory: territory75,
    allow_to_manage_teams: false,
    allow_to_manage_access_rights: false,
    allow_to_invite_agents: false,
  }]
)
agent_org_paris_nord_pmi_marco.skip_confirmation!
agent_org_paris_nord_pmi_marco.save!

agent_org_paris_nord_pmi_elsa = Agent.new(
  email: "edeck@pmi.rdv.fr",
  uid: "edeck@pmi.rdv.fr",
  first_name: "Elsa",
  last_name: "Deck",
  password: ENV["DB_SEEDS_USERS_AND_AGENTS_PASSWORD"],
  services: [service_pmi],
  invitation_accepted_at: 10.days.ago,
  last_sign_in_at: 2.days.ago,
  roles_attributes: [{ organisation: org_paris_nord, access_level: AgentRole::ACCESS_LEVEL_BASIC }],
  agent_territorial_access_rights_attributes: [{
    territory: territory75,
    allow_to_manage_teams: false,
    allow_to_manage_access_rights: false,
    allow_to_invite_agents: false,
  }]
)
agent_org_paris_nord_pmi_elsa.skip_confirmation!
agent_org_paris_nord_pmi_elsa.save!

agent_org_paris_nord_social_polo = Agent.new(
  email: "pdurant@social.rdv.fr",
  uid: "pdurant@social.rdv.fr",
  first_name: "Polo",
  last_name: "Durant",
  password: ENV["DB_SEEDS_USERS_AND_AGENTS_PASSWORD"],
  services: [service_social],
  invitation_accepted_at: 10.days.ago,
  roles_attributes: [{ organisation: org_paris_nord, access_level: AgentRole::ACCESS_LEVEL_BASIC }],
  agent_territorial_access_rights_attributes: [{
    territory: territory75,
    allow_to_manage_teams: false,
    allow_to_manage_access_rights: false,
    allow_to_invite_agents: false,
  }]
)
agent_org_paris_nord_social_polo.skip_confirmation!
agent_org_paris_nord_social_polo.save!

org_arques_pmi_maya = Agent.new(
  email: "mpatrick@pmi.rdv.fr",
  uid: "mpatrick@pmi.rdv.fr",
  first_name: "Maya",
  last_name: "Patrick",
  password: ENV["DB_SEEDS_USERS_AND_AGENTS_PASSWORD"],
  services: [service_pmi],
  invitation_accepted_at: 10.days.ago,
  roles_attributes: Organisation.where(territory: territory62).pluck(:id).map { { organisation_id: _1, access_level: AgentRole::ACCESS_LEVEL_ADMIN } },
  agent_territorial_access_rights_attributes: [{
    territory: territory62,
    allow_to_manage_teams: true,
    allow_to_manage_access_rights: true,
    allow_to_invite_agents: true,
  }]
)
org_arques_pmi_maya.skip_confirmation!
org_arques_pmi_maya.save!
org_arques_pmi_maya.territorial_roles.create!(territory: territory62)

agent_org_bapaume_pmi_bruno = Agent.new(
  email: "bfrangi@pmi.rdv.fr",
  uid: "bfrangi@pmi.rdv.fr",
  first_name: "Bruno",
  last_name: "Frangi",
  password: ENV["DB_SEEDS_USERS_AND_AGENTS_PASSWORD"],
  services: [service_pmi],
  invitation_accepted_at: 10.days.ago,
  roles_attributes: [{ organisation: org_bapaume, access_level: AgentRole::ACCESS_LEVEL_ADMIN }],
  agent_territorial_access_rights_attributes: [{
    territory: territory62,
    allow_to_manage_teams: false,
    allow_to_manage_access_rights: false,
    allow_to_invite_agents: false,
  }]
)
agent_org_bapaume_pmi_bruno.skip_confirmation!
agent_org_bapaume_pmi_bruno.save!
AgentTerritorialRole.create!(agent: agent_org_bapaume_pmi_bruno, territory: territory62)

agent_org_bapaume_pmi_gina = Agent.new(
  email: "gleone@pmi.rdv.fr",
  uid: "gleone@pmi.rdv.fr",
  first_name: "Gina",
  last_name: "Leone",
  password: ENV["DB_SEEDS_USERS_AND_AGENTS_PASSWORD"],
  services: [service_pmi],
  invitation_accepted_at: 10.days.ago,
  roles_attributes: [{ organisation: org_bapaume, access_level: AgentRole::ACCESS_LEVEL_ADMIN }],
  agent_territorial_access_rights_attributes: [{
    territory: territory62,
    allow_to_manage_teams: false,
    allow_to_manage_access_rights: false,
    allow_to_invite_agents: false,
  }]
)
agent_org_bapaume_pmi_gina.skip_confirmation!
agent_org_bapaume_pmi_gina.save!

# 95% des orgas ont moins de 32 agents
# cf https://rdv-service-public-metabase.osc-secnum-fr1.scalingo.io/question/858-pourcentile-95-nombre-dagents-par-orga
[
  ["Audran", "Lemaire"],
  ["Perrine", "Gay"],
  ["Malik", "Ziani"],
  ["Fatima", "Bensalem"],
  ["Paule", "Roussel"],
  ["Armeline", "Garcia"],
  ["Awa", "Diop"],
  ["Georgette", "Le Gall"],
  ["Octave", "Arnaud"],
  ["Séverine", "Marechal"],
  ["Ibrahim", "Coulibaly"],
  ["Hakim", "Belkacem"],
  ["Deniz", "Kaya"],
  ["Aurelle", "Guillot"],
  ["Inès", "Toumi"],
  ["Archange", "Gay"],
  ["Adeline", "Colin"],
  ["Régine", "Lemaire"],
  ["Blandine", "Berger"],
  ["João", "Carvalho"],
  ["Armand", "Klein"],
  ["Vital", "Bertrand"],
  ["Helena", "Santos"],
  ["Thanh", "Nguyen"],
  ["Didier", "Da Silva"],
].map do |first_name, last_name|
  email = ["#{first_name[0]}#{last_name}".parameterize.tr("-", ""), "@social.rdv.fr"].join
  Agent.new(
    first_name:, last_name:,
    created_at: now, updated_at: now,
    email:, uid: email,
    invitation_accepted_at: 10.days.ago,
    last_sign_in_at: 2.days.ago,
    password: ENV["DB_SEEDS_USERS_AND_AGENTS_PASSWORD"],
    services: [service_social],
    roles_attributes: [{ organisation: org_paris_nord, access_level: AgentRole::ACCESS_LEVEL_BASIC }],
    agent_territorial_access_rights_attributes: [
      { territory: territory75, allow_to_manage_teams: false, allow_to_manage_access_rights: false, allow_to_invite_agents: false },
    ]
  ).tap(&:skip_confirmation!).save!
end

# invited agents that have not accepted yet
# bypass validations since this mirrors AdminCreatesAgent behavior with allow_blank_name
# the agent is in "invited, not yet accepted" state so name is optional
%w[
  acaron@social.rdv.fr
  dfabre@social.rdv.fr
  fguyot@social.rdv.fr
].each do |email|
  agent = Agent.new(
    email: email, uid: email,
    invitation_sent_at: now,
    password: ENV["DB_SEEDS_USERS_AND_AGENTS_PASSWORD"], # password required to avoid validation errors
    services: [service_social],
    roles_attributes: [{ organisation: org_paris_nord, access_level: AgentRole::ACCESS_LEVEL_BASIC }],
    agent_territorial_access_rights_attributes: [
      { territory: territory75, allow_to_manage_teams: false, allow_to_manage_access_rights: false, allow_to_invite_agents: false },
    ]
  )
  agent.allow_blank_name = true
  agent.save!
end

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
_plage_ouverture_org_paris_nord_martine_ponctuelle = PlageOuverture.create!(
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
_plage_ouverture_org_paris_nord_polo_perm = PlageOuverture.create!(
  title: "Perm. sociale",
  organisation_id: org_paris_nord.id,
  agent_id: agent_org_paris_nord_social_polo.id,
  lieu_id: lieu_org_paris_nord_bd_aubervilliers.id,
  motif_ids: [motif_org_paris_nord_social_rappel.id, motif_org_paris_nord_social_suivi.id],
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
  motif_ids: [motifs[org_arques][:pmi_rappel].id, motifs[org_arques][:pmi_prenatale].id],
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
  motif_ids: [motifs[org_arques][:pmi_rappel].id, motifs[org_bapaume][:pmi_prenatale].id],
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
    motif_ids: [motifs[org_bapaume][:pmi_prenatale].id],
    first_day: Date.tomorrow,
    start_time: Tod::TimeOfDay.new(11),
    end_time: Tod::TimeOfDay.new(18),
    recurrence: Montrose.every(:week, interval: 1, starts: Date.tomorrow, day: [weekday])
  )
end

# RDVs

# RDVs à venir pour Martine : quelques RDVs espacés sur les deux prochaines semaines,
# posés sur des jours ouvrés quel que soit le jour où les seeds sont exécutés
prochains_jours_ouvres = (Date.tomorrow..Date.tomorrow + 3.weeks).select(&:on_weekday?)

Rdv.create!(
  starts_at: prochains_jours_ouvres[0].in_time_zone + 10.hours + 30.minutes,
  duration_in_min: 30,
  motif_id: motif_org_paris_nord_pmi_rappel.id,
  lieu: nil,
  organisation_id: org_paris_nord.id,
  agent_ids: [agent_org_paris_nord_pmi_martine.id],
  user_ids: [user_org_paris_nord_patricia.id],
  context: "Rappel suite à la consultation prénatale",
  created_by: agent_org_paris_nord_pmi_martine
)
Rdv.create!(
  starts_at: prochains_jours_ouvres[2].in_time_zone + 15.hours,
  duration_in_min: 30,
  motif_id: motif_org_paris_nord_pmi_suivi.id,
  lieu: lieu_org_paris_nord_bolivar,
  organisation_id: org_paris_nord.id,
  agent_ids: [agent_org_paris_nord_pmi_martine.id],
  user_ids: [user_org_paris_nord_josephine.id],
  context: "Suivi vaccins",
  created_by: agent_org_paris_nord_pmi_martine
)
Rdv.create!(
  starts_at: prochains_jours_ouvres[4].in_time_zone + 11.hours,
  duration_in_min: 60,
  motif_id: motif_org_paris_nord_pmi_securite.id,
  lieu: nil,
  organisation_id: org_paris_nord.id,
  agent_ids: [agent_org_paris_nord_pmi_martine.id],
  user_ids: [user_org_paris_nord_jean.id],
  context: "Visite à domicile",
  created_by: agent_org_paris_nord_pmi_martine
)
Rdv.create!(
  starts_at: prochains_jours_ouvres[5].in_time_zone + 9.hours + 30.minutes,
  duration_in_min: 45,
  motif_id: motif_org_paris_nord_pmi_prenatale.id,
  lieu: lieu_org_paris_nord_bolivar,
  organisation_id: org_paris_nord.id,
  agent_ids: [agent_org_paris_nord_pmi_martine.id],
  user_ids: [user_org_paris_nord_lea.id],
  context: "Première consultation prénatale",
  created_by: agent_org_paris_nord_pmi_martine
)
Rdv.create!(
  starts_at: prochains_jours_ouvres[6].in_time_zone + 16.hours,
  duration_in_min: 30,
  motif_id: motif_org_paris_nord_pmi_gyneco.id,
  lieu: nil,
  organisation_id: org_paris_nord.id,
  agent_ids: [agent_org_paris_nord_pmi_martine.id],
  user_ids: [user_org_paris_nord_lea.id],
  context: "Renouvellement contraception",
  created_by: agent_org_paris_nord_pmi_martine
)
Rdv.create!(
  starts_at: prochains_jours_ouvres[8].in_time_zone + 14.hours,
  duration_in_min: 30,
  motif_id: motif_org_paris_nord_pmi_suivi.id,
  lieu: lieu_org_paris_nord_bd_aubervilliers,
  organisation_id: org_paris_nord.id,
  agent_ids: [agent_org_paris_nord_pmi_martine.id],
  user_ids: [user_org_paris_nord_josephine.id],
  context: "Bilan de santé de l'enfant",
  created_by: agent_org_paris_nord_pmi_martine
)

10.times do |i|
  Rdv.create!(
    starts_at: Time.zone.today + 17.hours + i.weeks,
    duration_in_min: 60,
    motif_id: motif_org_paris_nord_pmi_collectif.id,
    lieu: lieu_org_paris_nord_bd_aubervilliers,
    organisation_id: org_paris_nord.id,
    agent_ids: [agent_org_paris_nord_pmi_marco.id],
    created_by: agent_org_paris_nord_pmi_marco,
    users_count: 0,
    user_ids: []
  )

  Rdv.create!(
    starts_at: Time.zone.today + 2.days + 16.hours + i.weeks,
    duration_in_min: 60,
    motif_id: motif_org_paris_nord_pmi_collectif.id,
    lieu: lieu_org_paris_nord_bolivar,
    organisation_id: org_paris_nord.id,
    agent_ids: [agent_org_paris_nord_pmi_elsa.id],
    created_by: agent_org_paris_nord_pmi_elsa,
    users_count: 0,
    user_ids: []
  )
end

# 11 RDVs en binôme Martine+Marco sur le mois écoulé : s'il y a des bugs de dédoublonnage
# (des RDVs en double, des participations orphelines) ils seront visibles dans la pagination en dev
jours_ouvres_binome = (1.month.ago.to_date - 4..1.month.ago.to_date + 20).select(&:on_weekday?).first(11)
[
  [jours_ouvres_binome[0].in_time_zone + 9.hours, 45, motif_org_paris_nord_pmi_prenatale, user_org_paris_nord_patricia, lieu_org_paris_nord_bolivar, "Consultation prénatale"],
  [jours_ouvres_binome[1].in_time_zone + 11.hours, 30, motif_org_paris_nord_pmi_suivi, user_org_paris_nord_josephine, lieu_org_paris_nord_bolivar, "Suivi vaccins"],
  [jours_ouvres_binome[2].in_time_zone + 14.hours + 30.minutes, 30, motif_org_paris_nord_pmi_gyneco, user_org_paris_nord_lea, nil, "Renouvellement contraception"],
  [jours_ouvres_binome[3].in_time_zone + 10.hours, 60, motif_org_paris_nord_pmi_securite, user_org_paris_nord_jean, nil, "Visite à domicile"],
  [jours_ouvres_binome[4].in_time_zone + 16.hours, 45, motif_org_paris_nord_pmi_prenatale, user_org_paris_nord_patricia, lieu_org_paris_nord_bolivar, "Suivi de grossesse"],
  [jours_ouvres_binome[5].in_time_zone + 9.hours + 30.minutes, 30, motif_org_paris_nord_pmi_suivi, user_org_paris_nord_josephine, lieu_org_paris_nord_bolivar, "Suivi après naissance"],
  [jours_ouvres_binome[6].in_time_zone + 15.hours, 30, motif_org_paris_nord_pmi_gyneco, user_org_paris_nord_lea, nil, "Consultation gynécologie"],
  [jours_ouvres_binome[7].in_time_zone + 10.hours, 60, motif_org_paris_nord_pmi_securite, user_org_paris_nord_jean, nil, "Conseils sécurité du domicile"],
  [jours_ouvres_binome[8].in_time_zone + 14.hours, 45, motif_org_paris_nord_pmi_prenatale, user_org_paris_nord_patricia, lieu_org_paris_nord_bolivar, "Consultation prénatale"],
  [jours_ouvres_binome[9].in_time_zone + 11.hours, 30, motif_org_paris_nord_pmi_suivi, user_org_paris_nord_josephine, lieu_org_paris_nord_bolivar, "Bilan de santé de l'enfant"],
  [jours_ouvres_binome[10].in_time_zone + 9.hours, 15, motif_org_paris_nord_pmi_rappel, user_org_paris_nord_lea, nil, "Rappel téléphonique"],
].each do |starts_at, duration_in_min, motif, user, lieu, context|
  Rdv.create!(
    starts_at:,
    duration_in_min:,
    motif_id: motif.id,
    lieu:,
    organisation_id: org_paris_nord.id,
    agent_ids: [agent_org_paris_nord_pmi_martine.id, agent_org_paris_nord_pmi_marco.id],
    user_ids: [user.id],
    status: "seen",
    context:,
    created_by: agent_org_paris_nord_pmi_martine
  )
end

# Beaucoup de RDVs sur les deux dernières années, pour un agenda réaliste : journées sans RDV,
# créneaux irréguliers, usagers, motifs, lieux et statuts variés.
# Les tirages passent par un PRNG seedé pour que les données générées soient déterministes.
# rubocop:disable Rails/SkipsModelValidations
rng = Random.new(42)
planning_user_ids = [user_org_paris_nord_patricia, user_org_paris_nord_josephine, user_org_paris_nord_lea, user_org_paris_nord_jean].map(&:id) +
                    user_ids.sample(150, random: rng)
planning_motifs = [
  [motif_org_paris_nord_pmi_prenatale, lieu_org_paris_nord_bolivar.id, 45, ["Consultation prénatale", "Suivi de grossesse"]],
  [motif_org_paris_nord_pmi_suivi, lieu_org_paris_nord_bolivar.id, 30, ["Suivi vaccins", "Bilan de santé de l'enfant", "Suivi après naissance"]],
  [motif_org_paris_nord_pmi_securite, nil, 60, ["Visite à domicile", "Conseils sécurité du domicile"]],
  [motif_org_paris_nord_pmi_gyneco, nil, 30, ["Renouvellement contraception", "Consultation gynécologie"]],
  [motif_org_paris_nord_pmi_rappel, nil, 15, ["Rappel téléphonique", "Renseignements administratifs"]],
]
planning_statuses = %w[seen seen seen seen seen seen unknown unknown unknown excused noshow revoked]
rdv_attributes = []
rdv_user_ids = []
2.years.ago.to_date.upto(Time.zone.yesterday.to_date) do |day|
  next if day.on_weekend?
  next if rng.rand(6).zero? # journée sans rdv, pour aérer l'agenda

  starts_at = day.in_time_zone + 9.hours + rng.rand(3).hours + [0, 15, 30, 45].sample(random: rng).minutes
  while starts_at.hour < 17
    motif, lieu_id, duration_in_min, contexts = planning_motifs.sample(random: rng)
    status = planning_statuses.sample(random: rng)
    rdv_attributes << {
      created_at: now,
      updated_at: now,
      starts_at:,
      ends_at: starts_at + duration_in_min.minutes,
      motif_id: motif.id,
      lieu_id:,
      status:,
      cancelled_at: status.in?(%w[excused noshow revoked]) ? starts_at - 1.day : nil,
      context: contexts.sample(random: rng),
      organisation_id: org_paris_nord.id,
      created_by_type: "Agent",
      created_by_id: agent_org_paris_nord_pmi_martine.id,
    }
    rdv_user_ids << planning_user_ids.sample(random: rng)
    starts_at += duration_in_min.minutes + rng.rand(15..75).minutes
  end
end
results = Rdv.insert_all!(rdv_attributes, returning: Arel.sql("id")) # [{"id"=>1}, {"id"=>2}, ...]
rdv_ids = results.flat_map(&:values) # [1, 2, ...]
agent_rdv_attributes = rdv_ids.map { |id| { agent_id: agent_org_paris_nord_pmi_martine.id, rdv_id: id } }
AgentsRdv.insert_all!(agent_rdv_attributes)
participations_attributes = rdv_ids.each_with_index.map do |id, index|
  {
    user_id: rdv_user_ids[index],
    rdv_id: id,
    status: rdv_attributes[index][:status],
    send_lifecycle_notifications: true,
    send_reminder_notification: true,
    created_by_type: "Agent",
    created_by_id: agent_org_paris_nord_pmi_martine.id,
  }
end
Participation.insert_all!(participations_attributes)
events = %w[new_creneau_available rdv_cancelled rdv_created rdv_date_updated rdv_upcoming_reminder]
receipts_attributes = rdv_ids.each_with_index.map do |id, index|
  {
    rdv_id: id,
    user_id: rdv_user_ids[index],
    organisation_id: org_paris_nord.id,
    event: events.sample(random: rng),
    channel: Receipt.channels.values.sample(random: rng),
    result: Receipt.results.values.sample(random: rng),
    created_at: now, updated_at: now,
  }
end
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
