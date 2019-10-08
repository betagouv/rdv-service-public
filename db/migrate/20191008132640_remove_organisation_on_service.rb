class RemoveOrganisationOnService < ActiveRecord::Migration[6.0]
  def change
    remove_column :services, :organisation_id
  end
end
