class AddStatusToInstanceExport < ActiveRecord::Migration[7.2]
  def change
    add_column :instance_exports, :status, :string
  end
end
