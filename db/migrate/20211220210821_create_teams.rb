class CreateTeams < ActiveRecord::Migration[6.0]
  def change
    create_table :teams do |t|
      t.belongs_to :territory
      t.string :name, index: { unique: true }
      t.timestamps
    end

    create_table :agent_teams do |t|
      t.belongs_to :team
      t.belongs_to :agent
      t.timestamps
    end
  end
end
