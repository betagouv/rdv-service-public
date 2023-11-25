class AddVerticaleToServices < ActiveRecord::Migration[7.0]
  def change
    add_column :services, :verticale, :verticale
  end
end
