class AddCaldavIdToAgentsRdvs < ActiveRecord::Migration[7.2]
  disable_ddl_transaction!

  def change
    add_column :agents_rdvs, :caldav_url, :string

    add_index :agents_rdvs, :caldav_url, where: "caldav_url IS NOT NULL", algorithm: :concurrently
  end
end
