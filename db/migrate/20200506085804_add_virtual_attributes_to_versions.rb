class AddVirtualAttributesToVersions < ActiveRecord::Migration[6.0]
  def change
    add_column :versions, :virtual_attributes, :json
  end
end
