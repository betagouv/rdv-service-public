class AddPublicIdToOrganisations < ActiveRecord::Migration[8.0]
  def up
    add_column :organisations, :public_link_id, :string

    Organisation.all.find_each do |org|
      org.update_columns(public_link_id: SecureRandom.base58(10))
    end

    add_check_constraint :organisations, "public_link_id IS NOT NULL", name: "organisations_public_link_id_null", validate: false
  end

  def down
    remove_column :organisations, :public_link_id
  end
end
