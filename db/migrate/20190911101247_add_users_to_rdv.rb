class AddUsersToRdv < ActiveRecord::Migration[5.2]
  def change
    create_table :rdvs_users, id: false do |t|
      t.belongs_to :rdv, index: true
      t.belongs_to :user, index: true
    end
  end
end
