class AddProconnectSiretToAgents < ActiveRecord::Migration[7.1]
  def change
    add_column :agents, :proconnect_siret, :string
  end
end
