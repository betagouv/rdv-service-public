class RenameStartAtToStartsAt < ActiveRecord::Migration[6.0]
  def change
    rename_column :rdvs, :start_at, :starts_at
  end
end
