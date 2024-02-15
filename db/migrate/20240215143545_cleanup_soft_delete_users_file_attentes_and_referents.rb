class CleanupSoftDeleteUsersFileAttentesAndReferents < ActiveRecord::Migration[7.0]
  def up
    FileAttente.where(user: User.unscoped.where.not(deleted_at: nil)).destroy_all
    ReferentAssignation.where(user: User.unscoped.where.not(deleted_at: nil)).destroy_all
  end

  def down; end
end
