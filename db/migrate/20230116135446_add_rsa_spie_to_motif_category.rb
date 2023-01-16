# frozen_string_literal: true

class AddRsaSpieToMotifCategory < ActiveRecord::Migration[7.0]
  def change
    add_enum_value :motif_category, "rsa_spie"
  end
end
