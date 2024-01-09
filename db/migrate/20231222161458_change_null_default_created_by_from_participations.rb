class ChangeNullDefaultCreatedByFromParticipations < ActiveRecord::Migration[7.0]
  def up
    change_column_null :participations, :created_by, true
  end

  def down
    change_column_null :participations, :created_by, false
  end
end
