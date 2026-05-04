class AddInstanceNameToTerritories < ActiveRecord::Migration[8.0]
  def change
    add_column :territories, :instance, :string,
               comment: "Permet de savoir si le territoire a vocation à être sur l'instance de l'ANCT ou de la DINUM. Une valeur null indique qu'on ne sait pas encore."
  end
end
