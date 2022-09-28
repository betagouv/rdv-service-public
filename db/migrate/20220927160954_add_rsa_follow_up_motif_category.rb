# frozen_string_literal: true

class AddRsaFollowUpMotifCategory < ActiveRecord::Migration[6.1]
  def change
    add_enum_value :motif_category, "rsa_follow_up"
  end
end
