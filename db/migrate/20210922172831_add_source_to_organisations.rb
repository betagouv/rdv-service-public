class AddSourceToOrganisations < ActiveRecord::Migration[6.0]
  def change
    add_column :organisations, :source, :string
  end
end
