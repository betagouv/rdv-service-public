class AddAmiEnabledToOrganisations < ActiveRecord::Migration[8.0]
  def change
    add_column :organisations, :ami_enabled, :boolean, default: false, null: false
  end
end
