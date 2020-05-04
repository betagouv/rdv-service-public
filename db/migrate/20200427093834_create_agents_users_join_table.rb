class CreateAgentsUsersJoinTable < ActiveRecord::Migration[6.0]
  def change
    create_table :agents_users do |t|
      t.belongs_to :user
      t.belongs_to :agent
    end
  end
end
