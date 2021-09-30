# frozen_string_literal: true

class Motif < ApplicationRecord
  has_paper_trail

  include PgSearch::Model

  pg_search_scope(
    :search_by_text,
    against: { name: "A" },
    using: { tsearch: { prefix: true, dictionary: "french", tsvector_column: "search_terms" } }
  )

  auto_strip_attributes :name, :color

  belongs_to :organisation
  belongs_to :service
  has_many :rdvs, dependent: :restrict_with_exception
  has_and_belongs_to_many :plage_ouvertures, -> { distinct }

  VISIBLE_AND_NOTIFIED = "visible_and_notified"
  VISIBLE_AND_NOT_NOTIFIED = "visible_and_not_notified"
  INVISIBLE = "invisible"
  VISIBILITY_TYPES = [VISIBLE_AND_NOTIFIED, VISIBLE_AND_NOT_NOTIFIED, INVISIBLE].freeze

  SECTORISATION_LEVEL_AGENT = "agent"
  SECTORISATION_LEVEL_ORGANISATION = "organisation"
  SECTORISATION_LEVEL_DEPARTEMENT = "departement"
  SECTORISATION_TYPES = [SECTORISATION_LEVEL_AGENT, SECTORISATION_LEVEL_ORGANISATION, SECTORISATION_LEVEL_DEPARTEMENT].freeze

  enum location_type: { public_office: 0, phone: 1, home: 2 }

  validates :visibility_type, inclusion: { in: VISIBILITY_TYPES }
  validates :sectorisation_level, inclusion: { in: SECTORISATION_TYPES }
  validates :name, presence: true, uniqueness: { scope: %i[organisation location_type service],
                                                 conditions: -> { where(deleted_at: nil) } }

  delegate :service_social?, to: :service

  validates :color, :service, :default_duration_in_min, :min_booking_delay, :max_booking_delay, presence: true
  validates :min_booking_delay, numericality: { greater_than_or_equal_to: 30.minutes, less_than_or_equal_to: 1.year.minutes }
  validates :max_booking_delay, numericality: { greater_than_or_equal_to: 30.minutes, less_than_or_equal_to: 1.year.minutes }
  validate :booking_delay_validation
  validate :not_associated_with_secretariat
  validates :color, css_hex_color: true

  scope :active, lambda { |active = true|
    active ? where(deleted_at: nil) : where.not(deleted_at: nil)
  }
  scope :reservable_online, -> { where(reservable_online: true) }
  scope :not_reservable_online, -> { where(reservable_online: false) }
  scope :by_phone, -> { Motif.phone } # default scope created by enum
  scope :for_secretariat, -> { where(for_secretariat: true) }
  scope :ordered_by_name, -> { order(Arel.sql("unaccent(LOWER(motifs.name))")) }
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
    name, location_type = Motif.location_types.keys.map do
      match_data = name_with_location_type&.match(/(.*)-#{_1}$/)
      match_data ? [match_data[1], _1] : nil
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
  def soft_delete
    rdvs.any? ? update_attribute(:deleted_at, Time.zone.now) : destroy
  end

  delegate :name, to: :service, prefix: true

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
    for_secretariat ? [service, Service.secretariat] : [service]
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
    custom_cancel_warning_message || I18n.t("activerecord.attributes.motif.default_cancel_warning_message")
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
end
