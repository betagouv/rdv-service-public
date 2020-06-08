class Lieu < ApplicationRecord
  belongs_to :organisation
  has_many :plage_ouvertures, dependent: :restrict_with_error
  validates :name, :address, :latitude, :longitude, presence: true

  scope :for_motif, lambda { |motif|
    lieux_ids = PlageOuverture
      .where.not("recurrence IS ? AND first_day < ?", nil, Time.zone.today)
      .joins(:motifs)
      .where(motifs: { id: motif.id, deleted_at: nil })
      .map(&:lieu_id)
      .uniq
    where(id: lieux_ids)
  }

  scope :for_motif_and_departement, lambda { |motif_name, departement|
    motifs_ids = Motif.active.reservable_online.joins(:organisation).where(organisations: { departement: departement }, name: motif_name)
    lieux_ids = PlageOuverture
      .where.not("recurrence IS ? AND first_day < ?", nil, Time.zone.today)
      .joins(:motifs)
      .where(motifs: { id: motifs_ids })
      .map(&:lieu_id)
      .uniq
    where(id: lieux_ids)
  }

  scope :for_service_motif_and_departement, lambda { |service_id, motif_name, departement|
    motifs_ids = Motif.active.reservable_online.joins(:organisation).where(organisations: { departement: departement }, name: motif_name, service_id: service_id)
    lieux_ids = PlageOuverture
      .where.not("recurrence IS ? AND first_day < ?", nil, Time.zone.today)
      .joins(:motifs)
      .where(motifs: { id: motifs_ids })
      .map(&:lieu_id)
      .uniq
    where(id: lieux_ids)
  }

  def full_name
    "#{name} (#{address})"
  end

  def distance(lat, lng)
    return 0 if latitude.nil? || longitude.nil?

    rad_per_deg = Math::PI / 180 # PI / 180
    earth_radius = 6371 * 1000 # Earth's radius in meter

    dlat_rad = (lat - latitude) * rad_per_deg
    dlon_rad = (lng - longitude) * rad_per_deg

    # Calculate square of half the chord length between latitude and longitude
    a = Math.sin(dlat_rad / 2)**2 +
        Math.cos((latitude / 180 * Math::PI)) * Math.cos((lat / 180 * Math::PI)) *
        Math.sin(dlon_rad / 2)**2

    # Calculate the angular distance in radians
    c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a))

    # Distance in meter
    earth_radius * c
  end
end
