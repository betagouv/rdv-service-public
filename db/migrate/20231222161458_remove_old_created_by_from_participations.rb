class RemoveOldCreatedByFromParticipations < ActiveRecord::Migration[7.0]
  def up
    safety_assured { remove_column :participations, :created_by, :string }
    drop_enum :created_by
  end

  def down
    create_enum :created_by, %w[agent user prescripteur]
    add_column :participations, :created_by, :created_by
  end
end
