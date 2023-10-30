class AddAccompagnementCategoryFieldToMotifs < ActiveRecord::Migration[6.1]
  def change
    add_enum_value :motif_category, "rsa_accompagnement_social"
    add_enum_value :motif_category, "rsa_accompagnement_sociopro"
  end
end
