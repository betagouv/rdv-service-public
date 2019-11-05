class AddIndexToAvoidDuplicates < ActiveRecord::Migration[6.0]
  def change
    add_index :organisations_users, [:organisation_id, :user_id], :unique => true
  end
end
