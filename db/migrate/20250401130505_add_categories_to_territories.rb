class AddCategoriesToTerritories < ActiveRecord::Migration[7.1]
  def change
    add_column :territories, :category, :string

    change_column_comment :territories, :category, from: nil, to: <<~COMMENT
      La catégorie permet classifier les différents territoires principalement pour faire des statistiques dans metabase,
      et pour avoir un suivi approprié de chaque territoire pour notre équipe déploiement et support. Par exemple, les besoins d'une commune
      ne seront pas les mêmes que ceux d'un service de l'état.
    COMMENT
  end
end
