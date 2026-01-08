class AddPublicLinkIdToMotifs < ActiveRecord::Migration[8.0]
  def change
    add_column :motifs, :public_link_id, :string

    up_only do
      Motif.find_each do |motif|
        motif.update_columns(public_link_id: SecureRandom.base58(8)) # rubocop:disable Rails/SkipsModelValidations
      end
    end

    add_check_constraint :motifs, "public_link_id IS NOT NULL", name: "motifs_public_link_id_null", validate: false
  end
end
