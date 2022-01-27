# frozen_string_literal: true

class Lieu < ApplicationRecord
  include PhoneNumberValidation::HasPhoneNumber

  auto_strip_attributes :name

  belongs_to :organisation
  has_many :plage_ouvertures, dependent: :restrict_with_error
  has_many :motifs, through: :plage_ouvertures
  has_many :rdvs, dependent: :restrict_with_error
  validates :name, :address, :latitude, :longitude, presence: true

  scope :enabled, -> { where(enabled: true) }
  scope :disabled, -> { where.not(enabled: true) }

  scope :for_motif, lambda { |motif|
    lieux_ids = PlageOuverture
      .where.not("recurrence IS ? AND first_day < ?", nil, Time.zone.today)
      .joins(:motifs)
      .where(motifs: { id: motif.id, deleted_at: nil })
      .map(&:lieu_id)
      .uniq
    enabled.where(id: lieux_ids)
  }

  # TODO: remove this method in favor of CreneauBuilderService usage
  scope :with_open_slots_for_motifs, lambda { |motifs|
    enabled.where(
      id: PlageOuverture
        .where.not("recurrence IS ? AND first_day < ?", nil, Time.zone.today)
        .joins(:motifs)
        .where(motifs: { id: motifs.pluck(:id) })
        .map(&:lieu_id)
        .uniq
    )
  }

  scope :ordered_by_name, -> { order(Arel.sql("unaccent(LOWER(name))")) }

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
    a = (Math.sin(dlat_rad / 2)**2) +
        (Math.cos((latitude / 180 * Math::PI)) * Math.cos((lat / 180 * Math::PI)) *
        (Math.sin(dlon_rad / 2)**2))

    # Calculate the angular distance in radians
    c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a))

    # Distance in meter
    earth_radius * c
  end
end
