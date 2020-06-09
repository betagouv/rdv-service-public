class AddLieuToRdv < ActiveRecord::Migration[6.0]
  def up
    add_reference :rdvs, :lieu, foreign_key: true

    Rdv.joins(:motif).where(motifs: { location_type: :public_office }).each do |rdv|
      if rdv.location.present? && (lieu = Lieu.find_by(address: rdv.location))
        rdv.update(lieu_id: lieu.id, location: nil)
      end
    end
  end

  def down
    Rdv.joins(:motif).where(motifs: { location_type: :public_office }).each do |rdv|
      rdv.update(location: Lieu.find(rdv.id).address) if rdv.lieu_id.present?
    end

    remove_reference :rdvs, :lieu
  end
end
