class RemoveCreatedByEnum < ActiveRecord::Migration[7.0]
  def up
    safety_assured do
      execute <<-SQL.squish
        DROP TYPE created_by;
      SQL
    end
  end

  def down
    create_enum :created_by, %i[agent user prescripteur]
  end
end
