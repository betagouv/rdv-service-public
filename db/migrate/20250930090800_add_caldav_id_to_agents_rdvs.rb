class AddCaldavIdToAgentsRdvs < ActiveRecord::Migration[7.2]
  def change
    add_column :agents_rdvs, :caldav_url, :string
  end
end
