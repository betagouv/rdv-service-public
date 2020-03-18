class AddWithSecretariatToRdv < ActiveRecord::Migration[6.0]
  def up
    add_column :motifs, :for_secretariat, :boolean, default: false

    Motif.where(by_phone: true).each do |motif|
      motif.update(for_secretariat: true)
    end
  end

  def down
    Motif.where(for_secretariat: true).each do |motif|
      motif.update(by_phone: true)
    end

    remove_column :motifs, :for_secretariat
  end
end
