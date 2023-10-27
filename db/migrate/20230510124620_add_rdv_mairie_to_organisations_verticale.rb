class AddRdvMairieToOrganisationsVerticale < ActiveRecord::Migration[7.0]
  def change
    add_enum_value :verticale, "rdv_mairie"
  end
end
