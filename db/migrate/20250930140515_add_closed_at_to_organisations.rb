class AddClosedAtToOrganisations < ActiveRecord::Migration[7.2]
  def change
    add_column :organisations, :closed_at, :datetime, null: true

    change_column_comment(
      :organisations,
      :closed_at,
      from: nil,
      to: "Date de fermeture de l'organisation"
    )
  end
end
