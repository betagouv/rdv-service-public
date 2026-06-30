class AddRdvEtatToOrganisationVerticaleEnum < ActiveRecord::Migration[8.0]
  def change
    add_enum_value :verticale, "rdv_etat"
  end
end
