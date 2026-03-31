class AddHexColorToPlages < ActiveRecord::Migration[8.0]
  def change
    add_column :plage_ouvertures, :hex_color, :string, null: false, default: "#c6ecff", limit: 7
  end
end
