# frozen_string_literal: true

class AddRsaMainTendueToMotifCategory < ActiveRecord::Migration[6.1]
  def change
    add_enum_value :motif_category, "rsa_main_tendue"
  end
end
