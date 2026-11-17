# Comptes agents et users exposés sur les pages de connexion en dev et review app - cf app/lib/seed_accounts.rb
SEED_ACCOUNTS = SeedAccounts.yaml_config

# Keep rdv_insertion seed loading in first as rdv-insertion need specific ids for linking rdv-s and rdv-i models
# Check this pr : https://github.com/betagouv/rdv-insertion/pull/690
load Rails.root.join("db/seeds/rdv_insertion.rb")
load Rails.root.join("db/seeds/medico_social.rb")
load Rails.root.join("db/seeds/cnfs.rb")
load Rails.root.join("db/seeds/rdv_mairie.rb")
load Rails.root.join("db/seeds/cdad.rb")
load Rails.root.join("db/seeds/visioplainte.rb")
load Rails.root.join("db/seeds/ccas.rb")
load Rails.root.join("db/seeds/demarche_numerique.rb")
