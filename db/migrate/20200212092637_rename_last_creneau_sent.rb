class RenameLastCreneauSent < ActiveRecord::Migration[6.0]
  def change
    rename_column :file_attentes, :last_creneau_sent_starts_at, :last_creneau_sent_at
  end
end
