# frozen_string_literal: true

class AddRdvEditableByUserAndRdvCancellableByUserToMotifs < ActiveRecord::Migration[6.1]
  def change
    add_column :motifs, :rdvs_editable_by_user, :boolean, default: true
    add_column :motifs, :rdvs_cancellable_by_user, :boolean, default: true
  end
end
