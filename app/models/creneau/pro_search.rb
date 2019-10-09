class Creneau::ProSearch
  include ActiveModel::Model

  attr_accessor :motif_id, :lieu_id
  attr_writer :from_date, :pro_ids

  validates :motif_id, presence: true

  def motif
    Motif.find_by(id: motif_id)
  end

  def pros
    Pro.where(id: pro_ids)
  end

  def lieu
    Lieu.find_by(id: lieu_id)
  end

  def lieux
    if lieu_id.present?
      Lieu.where(id: lieu_id)
    else
      Lieu.for_motif(motif)
    end
  end

  def pro_ids
    @pro_ids&.reject(&:blank?)
  end

  def from_date
    Date.parse(@from_date)
  rescue StandardError
    Time.zone.today
  end
end
