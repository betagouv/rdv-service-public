class AddDeletedAtToRdvs < ActiveRecord::Migration[6.0]
  def up
    add_column :rdvs, :deleted_at, :datetime
    User.where.not(deleted_at: nil).each do |user|
      user.rdvs.active.each { |rdv| rdv.soft_delete_for_user(user) }
    end
  end

  def down
    remove_column :rdvs, :deleted_at
  end
end
