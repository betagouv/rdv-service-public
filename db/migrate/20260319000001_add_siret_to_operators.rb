class AddSiretToOperators < ActiveRecord::Migration[8.0]
  def change
    add_column :operators, :siret, :string
  end
end
