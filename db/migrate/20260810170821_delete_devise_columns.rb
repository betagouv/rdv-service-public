class DeleteDeviseColumns < ActiveRecord::Migration[8.0]
  def up
    safety_assured do
      remove_column :users, :encrypted_password
      remove_column :users, :reset_password_token
      remove_column :users, :reset_password_sent_at
      remove_column :users, :confirmed_at
      remove_column :users, :confirmation_token
      remove_column :users, :confirmation_sent_at
      remove_column :users, :unconfirmed_email
      remove_column :users, :invitation_token
      remove_column :users, :invitation_created_at
      remove_column :users, :invitation_sent_at
      remove_column :users, :invitation_accepted_at
      remove_column :users, :invitation_limit
      remove_column :users, :invited_by_type
      remove_column :users, :invited_by_id
      remove_column :users, :text_search_terms_with_notification_email
      remove_column :users, :notification_email
    end
  end
end
