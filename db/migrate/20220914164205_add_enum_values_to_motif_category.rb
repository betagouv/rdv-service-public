# frozen_string_literal: true

class AddEnumValuesToMotifCategory < ActiveRecord::Migration[6.1]
  def change
    add_enum_value :motif_category, "rsa_cer_signature"
    add_enum_value :motif_category, "rsa_insertion_offer"
  end
end
