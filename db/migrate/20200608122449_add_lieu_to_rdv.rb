class AddLieuToRdv < ActiveRecord::Migration[6.0]
  def up
    add_reference :rdvs, :lieu, foreign_key: true

    Rdv.joins(:motif).where(motifs: { location_type: :public_office }).each do |rdv|
      next if rdv.location.blank?

      lieu = Lieu.find_by(address: rdv.location)
      next if lieu.blank?

      rdv.update!(lieu_id: lieu.id, location: nil)
    end
  end

  def down
    Rdv.joins(:motif).each do |rdv|
      rdv.update!(location: rdv.address)
    end

    remove_reference :rdvs, :lieu
  end
end
