class AddCreatedByFieldsToRdvs < ActiveRecord::Migration[7.0]
  def change
    add_column :rdvs, :created_by_id, :integer
    add_column :rdvs, :created_by_type, :string
  end
end
