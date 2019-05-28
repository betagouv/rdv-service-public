class AddOrganisationToPros < ActiveRecord::Migration[5.2]
  def change
    add_column :pros, :organisation_id, :bigint
    add_index :pros, :organisation_id
  end
end
