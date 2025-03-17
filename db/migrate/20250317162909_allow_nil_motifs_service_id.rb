class AllowNilMotifsServiceId < ActiveRecord::Migration[7.1]
  def change
    change_column_null :motifs, :service_id, true
  end
end
