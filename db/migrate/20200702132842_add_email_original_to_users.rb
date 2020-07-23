class AddEmailOriginalToUsers < ActiveRecord::Migration[6.0]
  def up
    add_column :users, :email_original, :string
    User.where.not(deleted_at: nil).each do |user|
      user.update_columns(email_original: user.email, email: user.deleted_email)
      # skip callbacks to avoid mail confirmation
    end
  end

  def down
    User.where.not(deleted_at: nil).each do |user|
      user.update_columns(email: user.email_original)
    end
    remove_column :users, :email_original
  end
end
