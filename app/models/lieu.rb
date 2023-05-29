# frozen_string_literal: true

class Lieu < ApplicationRecord
  # Mixins
  has_paper_trail
  include PhoneNumberValidation::HasPhoneNumber
  include WebhookDeliverable

  # Attributes
  auto_strip_attributes :name
  enum availability: { enabled: "enabled", disabled: "disabled", single_use: "single_use" }

  # TODO: supprimer cet attribut `:enabled` si bien lié au champ `old_enabled` (cf `schema.rb`)
  attribute :enabled, :boolean

  # Relations
  belongs_to :organisation
  has_many :plage_ouvertures, dependent: :restrict_with_error
  has_many :rdvs, dependent: :restrict_with_error
  has_many :webhook_endpoints, through: :organisation

  # Through relations
  has_many :motifs, through: :plage_ouvertures
  has_many :agents, through: :plage_ouvertures

  # Validations
  validates :name, :address, :availability, presence: true
  validate :longitude_and_latitude_must_be_present
  validate :cant_change_availibility_single_use

  # Scopes
  scope :for_motif, lambda { |motif|
    lieux_ids = PlageOuverture
      .where.not("recurrence IS ? AND first_day < ?", nil, Time.zone.today)
      .joins(:motifs)
      .where(motifs: { id: motif.id, archived_at: nil })
      .map(&:lieu_id)
      .uniq
    enabled.where(id: lieux_ids)
  }

  # TODO: remove this method in favor of CreneauBuilderService usage
  # CreneauBuilderService was replace by SlotBuilder, with lieu given.
  # Perhaps need to move this to an other function that allow to list lieux from
  # given parameters
  scope :with_open_slots_for_motifs, lambda { |motifs|
    plage_ouverture_lieu_ids = PlageOuverture.where.not("recurrence IS ? AND first_day < ?", nil, Time.zone.today)
      .joins(:motifs)
      .where(motifs: { id: motifs.pluck(:id) })
      .distinct
      .pluck(:lieu_id)
    rdv_collectif_lieu_ids = Rdv.collectif_and_available_for_reservation.where(motif_id: motifs.pluck(:id)).distinct.pluck(:lieu_id)

    enabled.where(id: plage_ouverture_lieu_ids + rdv_collectif_lieu_ids)
  }

  scope :ordered_by_name, -> { order(Arel.sql("unaccent(LOWER(name))")) }

  ## -
  alias enabled enabled?
  def enabled=(value)
    self.availability = value.to_bool ? :enabled : :disabled
  end

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

  private

  def longitude_and_latitude_must_be_present
    return if latitude.present? && longitude.present?

    errors.add(:address, :must_be_valid)
  end

  def cant_change_availibility_single_use
    return if new_record?
    return unless changes[:availability]&.include?("single_use")

    errors.add(:availability, :cant_change_from_or_to_single_use)
  end
end
