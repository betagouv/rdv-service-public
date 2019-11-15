class UserHasManyChildren < ActiveRecord::Migration[6.0]
  def change
    add_reference :users, :parent, foreign_key: { to_table: :users }
  end
end
