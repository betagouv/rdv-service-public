class AddPublicLinkIdToOrganisations < ActiveRecord::Migration[8.0]
  def change
    add_column :organisations, :public_link_id, :string

    up_only do
      Organisation.find_each do |org|
        org.update_columns(public_link_id: SecureRandom.base58(6))
      end
    end

    add_check_constraint :organisations, "public_link_id IS NOT NULL", name: "organisations_public_link_id_null", validate: false
  end
end
