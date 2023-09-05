# frozen_string_literal: true

class RemoveDeletedAtFromUsers < ActiveRecord::Migration[7.0]
  def change
    remove_column :users, :deleted_at, :datetime
  end
end
