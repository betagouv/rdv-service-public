# frozen_string_literal: true

# Keep rdv_insertion seed loading in first as rdv-insertion need specific ids for linking rdv-s and rdv-i models
# Check this pr : https://github.com/betagouv/rdv-insertion/pull/690
load Rails.root.join("db/seeds/rdv_insertion.rb")
load Rails.root.join("db/seeds/medico_social.rb")
load Rails.root.join("db/seeds/cnfs.rb")
