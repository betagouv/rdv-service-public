class RemoveNonNullConstraintFromByCreatedByTypeInParticipations < ActiveRecord::Migration[7.0]
  def change
    change_column_null :participations, :created_by_type, true
  end
end
