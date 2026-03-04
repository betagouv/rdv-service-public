class BackfillLatestLoginAtFromConfirmedAt < ActiveRecord::Migration[7.2]
  def up
    safety_assured { execute(<<~SQL.squish) }
      UPDATE users
      SET latest_login_at = confirmed_at
      WHERE confirmed_at IS NOT NULL
        AND latest_login_at IS NULL
    SQL
  end

  def down
    # Non réversible : on ne peut pas distinguer les latest_login_at qui venaient de confirmed_at
  end
end
