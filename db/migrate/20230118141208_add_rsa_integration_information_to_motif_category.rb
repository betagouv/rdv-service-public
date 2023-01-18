# frozen_string_literal: true

class AddRsaIntegrationInformationToMotifCategory < ActiveRecord::Migration[7.0]
  def change
    add_enum_value :motif_category, "rsa_integration_information"
  end
end
