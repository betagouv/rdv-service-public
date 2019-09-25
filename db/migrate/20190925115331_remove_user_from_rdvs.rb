class RemoveUserFromRdvs < ActiveRecord::Migration[6.0]
  def change
    remove_reference :rdvs, :user, index: true
  end
end
