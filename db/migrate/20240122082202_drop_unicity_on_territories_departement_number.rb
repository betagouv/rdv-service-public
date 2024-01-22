class DropUnicityOnTerritoriesDepartementNumber < ActiveRecord::Migration[7.0]
  disable_ddl_transaction!

  def change
    safety_assured do
      remove_index  :territories, :departement_number, unique: true, where: "((departement_number)::text <> ''::text)"
      add_index     :territories, :departement_number, unique: false, where: "((departement_number)::text <> ''::text)"
    end
  end
end
