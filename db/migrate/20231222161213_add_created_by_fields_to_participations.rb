class AddCreatedByFieldsToParticipations < ActiveRecord::Migration[7.0]
  def change
    add_column :participations, :created_by_id, :integer
    add_column :participations, :created_by_type, :string
  end
end
