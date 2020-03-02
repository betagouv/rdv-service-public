class RemoveRdvName < ActiveRecord::Migration[6.0]
  def change
    remove_column :rdvs, :name, :string
  end
end
