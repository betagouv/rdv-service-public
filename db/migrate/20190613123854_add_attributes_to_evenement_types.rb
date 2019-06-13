class AddAttributesToEvenementTypes < ActiveRecord::Migration[5.2]
  def change
    add_column :evenement_types, :accept_multiple_pros, :boolean, default: false, null: false
    add_column :evenement_types, :accept_multiple_users, :boolean, default: false, null: false
    add_column :evenement_types, :at_home, :boolean, default: false, null: false
    add_column :evenement_types, :default_duration_in_min, :integer, default: 30, null: false
  end
end
