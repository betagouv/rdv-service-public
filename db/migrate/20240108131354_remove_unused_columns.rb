class RemoveUnusedColumns < ActiveRecord::Migration[7.0]
  def change
    safety_assured do
      remove_column :organisations, :human_id, :string, default: "", null: false
      remove_column :organisations, :departement, :string

      remove_column :sectors, :departement, :string
    end
  end
end
