class AllowExternalReferenceWithoutTerritory < ActiveRecord::Migration[7.2]
  def change
    change_column_null :external_references, :territory_id, true
  end
end
