class RemoveSpecialiteFromOrganisation < ActiveRecord::Migration[5.2]
  def change
    remove_column :specialites, :organisation_id
  end
end
