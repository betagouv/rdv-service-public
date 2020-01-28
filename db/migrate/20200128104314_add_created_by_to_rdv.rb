class AddCreatedByToRdv < ActiveRecord::Migration[6.0]
  def change
    add_column :rdvs, :created_by, :integer, default: 0
    add_index :rdvs, :created_by
  end
end
