class AddRdvServicePublicVerticale < ActiveRecord::Migration[7.0]
  def change
    add_enum_value :verticale, "rdv_service_public"
  end
end
