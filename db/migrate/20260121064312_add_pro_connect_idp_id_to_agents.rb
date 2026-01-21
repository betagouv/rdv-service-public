class AddProConnectIdpIdToAgents < ActiveRecord::Migration[8.0]
  def change
    add_column :agents, :pro_connect_idp_id, :string, comment: "Fournisseur d'identité ProConnect (identity provider)"
  end
end
