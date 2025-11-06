class AddLieuxCodePostal < ActiveRecord::Migration[7.2]
  def change
    add_column :lieux, :code_postal, :string
  end
end
