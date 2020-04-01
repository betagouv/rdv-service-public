class AddLocationTypeToMotifs < ActiveRecord::Migration[6.0]
  def up
    add_column :motifs, :location_type, :integer, null: false, default: Motif.location_types[:public_office], after: :by_phone
    # this update_all will be re-done in the next commit to ensure that
    # all records are updated considering the release process
    # cf https://github.com/betagouv/rdv-solidarites.fr/pull/515
    # but we do it here anyhow in case we need to rollback
    Motif.where(by_phone: true).update_all(location_type: :phone)
  end

  def down
    Motif.where(location_type: :phone).update_all(by_phone: true)
    remove_column :motifs, :location_type
  end
end
