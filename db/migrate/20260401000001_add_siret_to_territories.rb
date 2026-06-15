class AddSiretToTerritories < ActiveRecord::Migration[8.0]
  def change
    add_column :territories, :siret, :string
  end
end
