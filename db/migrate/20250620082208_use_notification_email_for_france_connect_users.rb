class UseNotificationEmailForFranceConnectUsers < ActiveRecord::Migration[7.1]
  def up
    safety_assured do
      execute <<~SQL.squish
        UPDATE users
        SET
          notification_email = email,
          email = NULL
        WHERE
          encrypted_password = '' AND
          franceconnect_openid_sub IS NOT NULL AND
          email IS NOT NULL;
      SQL
    end
  end

  def down; end
end
