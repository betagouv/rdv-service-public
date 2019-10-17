class AddPhoneToMotifs < ActiveRecord::Migration[6.0]
  def change
    add_column :motifs, :by_phone, :boolean, default: false, null: false
  end
end
