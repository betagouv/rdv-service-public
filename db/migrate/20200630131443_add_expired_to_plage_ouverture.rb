class AddExpiredToPlageOuverture < ActiveRecord::Migration[6.0]
  def change
    add_column :plage_ouvertures, :expired_cached, :boolean, default: false
  end
end
