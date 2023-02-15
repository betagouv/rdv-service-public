# frozen_string_literal: true

class AddForeignKeyToSectorAttributionsOrganisationId < ActiveRecord::Migration[7.0]
  def change
    add_foreign_key :sector_attributions, :organisations
  end
end
