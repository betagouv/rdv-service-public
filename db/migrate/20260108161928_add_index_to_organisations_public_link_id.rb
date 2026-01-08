class AddIndexToOrganisationsPublicLinkId < ActiveRecord::Migration[8.0]
  disable_ddl_transaction!

  def change
    add_index :organisations, :public_link_id, unique: true, algorithm: :concurrently
  end
end
