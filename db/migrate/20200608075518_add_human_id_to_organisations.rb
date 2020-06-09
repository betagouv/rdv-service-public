class AddHumanIdToOrganisations < ActiveRecord::Migration[6.0]
  def change
    add_column :organisations, :human_id, :string
  end
end
