# bundle exec rails runner scripts/anonymiser_la_base.rb ID_TERRITOIRE

ID_TERRITOIRE = ARGV[0]

territory_to_keep = Territory.find(ID_TERRITOIRE)

# -------------------------------
# Partie 1 : suppression des RDVs
# -------------------------------

organisations_to_delete = Organisation.where.not(territory: territory_to_keep)
rdvs_to_delete = Rdv.where(organisation: organisations_to_delete)

# Suppression des tables qui ont une référence vers les RDVs
receipts = Receipt.where(organisation: organisations_to_delete)
participations = Participation.where(rdv: rdvs_to_delete)
agent_rdvs = AgentsRdv.where(rdv: rdvs_to_delete)
files_attente = FileAttente.where(rdv: rdvs_to_delete)
prescripteurs = Prescripteur.where(participation: participations)
prescripteurs.delete_all
receipts.delete_all
participations.delete_all
agent_rdvs.delete_all
files_attente.delete_all

rdvs_to_delete.delete_all

# -------------------------------
# Partie 2 : suppression des usagers
# -------------------------------
#
profiles_to_keep = UserProfile.where.not(organisation: organisations_to_delete)
users_to_delete = User.unscope.where.not(id: profiles_to_keep.select(:user_id))
user_profiles_to_delete = UserProfile.where(user: users_to_delete)
Participation.where(user: users_to_delete).delete_all
ReferentAssignation.where(user: users_to_delete).delete_all
FileAttente.where(user: users_to_delete).delete_all
Receipt.where(user: users_to_delete).delete_all
User.unscoped.where(responsible_id: users_to_delete).update_all(responsible_id: nil) # rubocop:disable Rails/SkipsModelValidations
user_profiles_to_delete.delete_all
users_to_delete.delete_all

# -------------------------------
# Partie 3 : Anonymisation des données restantes
# -------------------------------

Anonymizer.default_config.anonymize_table!("users")
Anonymizer.default_config.anonymize_table!("receipts")
Anonymizer.default_config.anonymize_table!("rdvs")
Anonymizer.default_config.truncated_tables.each(&:anonymize_all_records!)

# -------------------------------
# Épilogue : suppression des jobs et versions
# -------------------------------

GoodJob::Job.unscoped.delete_all
PaperTrail::Version.delete_all
