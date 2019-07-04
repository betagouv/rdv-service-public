class AddSpecialiteRefToMotifs < ActiveRecord::Migration[5.2]
  def change
    add_reference :motifs, :specialite, foreign_key: true
  end
end
