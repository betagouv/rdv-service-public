# frozen_string_literal: true

class AddRsaAtelierCollectifToMotifCategory < ActiveRecord::Migration[6.1]
  def change
    add_enum_value :motif_category, "rsa_atelier_collectif_mandatory"
  end
end
