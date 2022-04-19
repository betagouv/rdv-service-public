# frozen_string_literal: true

class AddInvitedThroughToUsersChangeCreatedThroughToEnumAndAddIndex < ActiveRecord::Migration[6.0]
  def change
    create_enum :user_invited_through, %w[devise_email external]
    add_column :users, :invited_through, :user_invited_through, default: "devise_email"

    rename_column :users, :created_through, :old_created_through

    create_enum :user_created_through, %w[unknown agent_creation user_sign_up franceconnect_sign_up user_relative_creation agent_creation_api]
    add_column :users, :created_through, :user_created_through, default: "unknown"

    up_only do
      created_through_values = %w[unknown agent_creation user_sign_up franceconnect_sign_up user_relative_creation agent_creation_api]
      created_through_values.each do |created_through_value|
        User.where(old_created_through: created_through_value).update_all(created_through: created_through_value)
      end
    end

    add_index :users, :created_through
  end
end
