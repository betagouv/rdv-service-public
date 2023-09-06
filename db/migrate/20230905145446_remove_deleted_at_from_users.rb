# frozen_string_literal: true

class RemoveDeletedAtFromUsers < ActiveRecord::Migration[7.0]
  def change
    reversible do |direction|
      direction.up do
        User.where.not(deleted_at: nil).each do
          user.skip_webhooks = true
          user.destroy
        end
      end
    end

    remove_column :users, :deleted_at, :datetime
  end
end
