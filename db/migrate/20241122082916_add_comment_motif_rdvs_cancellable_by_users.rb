class AddCommentMotifRdvsCancellableByUsers < ActiveRecord::Migration[7.1]
  def change
    change_column_comment :motifs, :rdvs_cancellable_by_user, from: nil, to: "Option invisible dans l’interface agents, utilisée par RDV Insertion pour des motifs de convocations"
  end
end
