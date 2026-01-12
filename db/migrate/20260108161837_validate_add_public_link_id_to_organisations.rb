class ValidateAddPublicLinkIdToOrganisations < ActiveRecord::Migration[8.0]
  def up
    validate_check_constraint :organisations, name: "organisations_public_link_id_null"
    change_column_null :organisations, :public_link_id, false
    remove_check_constraint :organisations, name: "organisations_public_link_id_null"
  end

  def down
    add_check_constraint :organisations, "public_link_id IS NOT NULL", name: "organisations_public_link_id_null", validate: false
    change_column_null :organisations, :public_link_id, true
  end
end
