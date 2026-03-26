class MigrateNotificationEmailToEmail < ActiveRecord::Migration[8.0]
  def up
    safety_assured do
      execute <<~SQL.squish
        UPDATE users SET email = notification_email
        WHERE email IS NULL AND notification_email IS NOT NULL
      SQL
    end
  end

  def down
    safety_assured do
      execute <<~SQL.squish
        UPDATE users SET email = NULL
        WHERE email IS NOT NULL AND notification_email IS NOT NULL
      SQL
    end
  end
end
