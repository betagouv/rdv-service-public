class RemoveOldCreatedByFromRdvs < ActiveRecord::Migration[7.0]
  def up
    safety_assured { remove_column :rdvs, :created_by, :string }
  end

  def down
    add_column :rdvs, :created_by, :created_by
  end
end
