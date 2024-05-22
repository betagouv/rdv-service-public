class SetMotifsRdvsEditableByUserFalseByDefault < ActiveRecord::Migration[7.0]
  def change
    change_column_default :motifs, :rdvs_editable_by_user, from: true, to: false

    reversible do |direction|
      direction.up do
        Motif.where(bookable_by: Motif.bookable_bies.fetch("agents")).update_all(rdvs_editable_by_user: false)
      end
    end
  end
end
