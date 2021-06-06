# frozen_string_literal: true

class AddInvitationPeriodToUser < ActiveRecord::Migration[6.0]
  def change
    add_column :users, :invite_for, :integer
  end
end
