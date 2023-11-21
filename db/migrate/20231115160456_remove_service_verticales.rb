class RemoveServiceVerticales < ActiveRecord::Migration[7.0]
  def change
    remove_column :services, :verticale, :verticale
  end
end
