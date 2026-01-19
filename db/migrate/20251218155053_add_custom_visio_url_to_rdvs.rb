class AddCustomVisioUrlToRdvs < ActiveRecord::Migration[8.0]
  def change
    add_column :rdvs, :visio_url_custom, :string
  end
end
