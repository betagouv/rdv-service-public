# frozen_string_literal: true

class Motif < ApplicationRecord
  # Mixins
  has_paper_trail

  include PgSearch::Model

  pg_search_scope(:search_by_text,
                  against: :name,
                  using: { tsearch: { prefix: true } },
                  ignoring: :accents) # Motif text search is not indexed, but at least we can use PG unaccent. See #1772 and #1833

  # Attributes
  auto_strip_attributes :name, :color

  # TODO: make it an enum
  VISIBLE_AND_NOTIFIED = "visible_and_notified"
  VISIBLE_AND_NOT_NOTIFIED = "visible_and_not_notified"
  INVISIBLE = "invisible"
  VISIBILITY_TYPES = [VISIBLE_AND_NOTIFIED, VISIBLE_AND_NOT_NOTIFIED, INVISIBLE].freeze

  # TODO: make it an enum
  SECTORISATION_LEVEL_AGENT = "agent"
  SECTORISATION_LEVEL_ORGANISATION = "organisation"
  SECTORISATION_LEVEL_DEPARTEMENT = "departement"
  SECTORISATION_TYPES = [SECTORISATION_LEVEL_AGENT, SECTORISATION_LEVEL_ORGANISATION, SECTORISATION_LEVEL_DEPARTEMENT].freeze

  enum location_type: { public_office: "public_office", phone: "phone", home: "home" }
  enum category: { rsa_orientation: "rsa_orientation",
                   rsa_accompagnement: "rsa_accompagnement",
                   rsa_orientation_on_phone_platform: "rsa_orientation_on_phone_platform",
                   rsa_cer_signature: "rsa_cer_signature",
                   rsa_insertion_offer: "rsa_insertion_offer", }

  # Relations
  belongs_to :organisation
  belongs_to :service
  has_many :rdvs, dependent: :restrict_with_exception
  has_and_belongs_to_many :plage_ouvertures, -> { distinct }

  # Through relations
  has_many :lieux, through: :plage_ouvertures

  # Delegates
  delegate :service_social?, to: :service
  delegate :name, to: :service, prefix: true

  # Hooks
  after_update -> { rdvs.touch_all }

  # Validation
  validates :visibility_type, inclusion: { in: VISIBILITY_TYPES }
  validates :sectorisation_level, inclusion: { in: SECTORISATION_TYPES }
  validates :name, presence: true, uniqueness: { scope: %i[organisation location_type service],
                                                 conditions: -> { where(deleted_at: nil) }, }

  validates :color, :default_duration_in_min, :min_booking_delay, :max_booking_delay, presence: true
  validates :min_booking_delay, numericality: { greater_than_or_equal_to: 30.minutes, less_than_or_equal_to: 1.year.minutes }
  validates :max_booking_delay, numericality: { greater_than_or_equal_to: 30.minutes, less_than_or_equal_to: 1.year.minutes }
  validate :booking_delay_validation
  validate :not_associated_with_secretariat
  validates :color, css_hex_color: true
  validate :not_reservable_online_if_collectif
  validate :not_at_home_if_collectif

  # Scopes
  scope :active, lambda { |active = true|
    active ? where(deleted_at: nil) : where.not(deleted_at: nil)
  }
  scope :reservable_online, -> { where(reservable_online: true) }
  scope :not_reservable_online, -> { where(reservable_online: false) }
  scope :by_phone, -> { Motif.phone } # default scope created by enum
  scope :for_secretariat, -> { where(for_secretariat: true) }
  scope :ordered_by_name, -> { order(Arel.sql("unaccent(LOWER(motifs.name))")) }
  scope :available_with_plages_ouvertures, -> { active.reservable_online.joins(:organisation, :plage_ouvertures) }
  scope :available_motifs_for_organisation_and_agent, lambda { |organisation, agent|
    available_motifs = if agent.admin_in_organisation?(organisation)
                         all
                       elsif agent.service.secretariat?
                         for_secretariat
                       else
                         where(service: agent.service)
                       end
    available_motifs.where(organisation_id: organisation.id).active.ordered_by_name
  }
  scope :search_by_name_with_location_type, lambda { |name_with_location_type|
    name, location_type = Motif.location_types.keys.map do |location_type|
      match_data = name_with_location_type&.match(/(.*)-#{location_type}$/)
      match_data ? [match_data[1], location_type] : nil
    end.compact.first
    where(name: name, location_type: location_type)
  }
  scope :sectorisation_level_departement, -> { where(sectorisation_level: SECTORISATION_LEVEL_DEPARTEMENT) }
  scope :sectorisation_level_organisation, -> { where(sectorisation_level: SECTORISATION_LEVEL_ORGANISATION) }
  scope :sectorisation_level_agent, -> { where(sectorisation_level: SECTORISATION_LEVEL_AGENT) }
  scope :in_departement, lambda { |departement_number|
    joins(organisation: :territory)
      .where(organisations: { territories: { departement_number: departement_number } })
  }
  scope :visible, -> { where(visibility_type: [Motif::VISIBLE_AND_NOTIFIED, Motif::VISIBLE_AND_NOT_NOTIFIED]) }
  scope :collectif, -> { where(collectif: true) }
  scope :individuel, -> { where(collectif: false) }

  ## -

  def to_s
    name
  end

  def soft_delete
    rdvs.any? ? update_attribute(:deleted_at, Time.zone.now) : destroy
  end

  def authorized_agents
    Agent
      .joins(:organisations)
      .where(organisations: { id: organisation.id })
      .complete
      .active
      .where(service: authorized_services)
      .order_by_last_name
  end

  def authorized_services
    for_secretariat ? [service, Service.secretariat.first] : [service]
  end

  def secretariat?
    for_secretariat?
  end

  def visible_and_notified?
    visibility_type == VISIBLE_AND_NOTIFIED
  end

  def name_with_location_type
    "#{name}-#{location_type}"
  end

  def sectorisation_level_agent?
    sectorisation_level == SECTORISATION_LEVEL_AGENT
  end

  def sectorisation_level_organisation?
    sectorisation_level == SECTORISATION_LEVEL_ORGANISATION
  end

  def sectorisation_level_departement?
    sectorisation_level == SECTORISATION_LEVEL_DEPARTEMENT
  end

  def cancellation_warning
    custom_cancel_warning_message || Motif.human_attribute_name("default_cancel_warning_message")
  end

  def start_booking_delay
    Time.zone.now + min_booking_delay.seconds
  end

  def end_booking_delay
    Time.zone.now + max_booking_delay.seconds
  end

  def booking_delay_range
    start_booking_delay..end_booking_delay
  end

  def individuel?
    !collectif?
  end

  private

  def booking_delay_validation
    return if min_booking_delay.zero? && max_booking_delay.zero?

    errors.add(:max_booking_delay, "doit être supérieur au délai de réservation minimum") if max_booking_delay <= min_booking_delay
  end

  def not_associated_with_secretariat
    return if service_id.nil?

    errors.add(:service_id, "ne peut être le secrétariat") if service.secretariat?
  end

  def not_reservable_online_if_collectif
    return unless collectif? && reservable_online

    errors.add(:base, :not_reservable_online_if_collectif)
  end

  def not_at_home_if_collectif
    return unless collectif? && !public_office?

    errors.add(:base, :not_at_home_if_collectif)
  end
end
