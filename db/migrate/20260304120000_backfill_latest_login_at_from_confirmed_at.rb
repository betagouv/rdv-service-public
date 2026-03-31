class BackfillLatestLoginAtFromConfirmedAt < ActiveRecord::Migration[8.0]
  def up
    User.where(latest_login_at: nil).where.not(confirmed_at: nil).in_batches do |batch|
      batch.update_all("latest_login_at = confirmed_at")
    end
  end

  def down
    # Non réversible : on ne peut pas distinguer les latest_login_at qui venaient de confirmed_at
  end
end
