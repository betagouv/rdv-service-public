class AddCreatedThroughToUsers < ActiveRecord::Migration[6.0]
  def up
    add_column :users, :created_through, :string
    User.where(invited_by_type: "Agent").update_all(created_through: "agent_creation")
    others = User.where(invited_by_type: nil)
    others.where(responsible_id: nil).update_all(created_through: "user_sign_up")
    others.where.not(responsible_id: nil).update_all(created_through: "unknown")
    # we cannot be sure for these ones whether the user or agent created them
    raise if User.where(created_through: nil).any?
  end

  def down
    remove_column :users, :created_through
  end
end
