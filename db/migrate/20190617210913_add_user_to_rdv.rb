class AddUserToRdv < ActiveRecord::Migration[5.2]
  def change
    add_reference :rdvs, :user, foreign_key: true
  end
end
