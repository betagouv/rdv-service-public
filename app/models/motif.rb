class Motif < ApplicationRecord
  has_paper_trail
  belongs_to :organisation
  belongs_to :service
  has_many :rdvs, dependent: :restrict_with_exception
  has_and_belongs_to_many :plage_ouvertures, -> { distinct }

  enum location_type: [:public_office, :phone, :home]
  validates :name, presence: true, uniqueness: { scope: [:organisation, :location_type], conditions: -> { where(deleted_at: nil) }, message: "est déjà utilisé pour un motif avec le même type de RDV" }

  delegate :service_social?, to: :service

  validates :color, :service, :default_duration_in_min, :min_booking_delay, :max_booking_delay, presence: true
  validates :min_booking_delay, numericality: { greater_than_or_equal_to: 30.minutes, less_than_or_equal_to: 1.year.minutes }
  validates :max_booking_delay, numericality: { greater_than_or_equal_to: 30.minutes, less_than_or_equal_to: 1.year.minutes }
  validate :booking_delay_validation
  validate :not_associated_with_secretariat

  scope :active, -> { where(deleted_at: nil) }
  scope :reservable_online, -> { where(reservable_online: true) }
  scope :by_phone, -> { Motif.phone } # default scope created by enum
  scope :for_secretariat, -> { where(for_secretariat: true) }
  scope :ordered_by_name, -> { order(Arel.sql("unaccent(LOWER(name))")) }
  scope :available_motifs_for_organisation_and_agent, lambda { |organisation, agent|
    available_motifs = if agent.service.secretariat?
                         for_secretariat
                       elsif agent.admin?
                         all
                       else
                         where(service: agent.service)
                       end
    available_motifs.where(organisation_id: organisation.id).active.ordered_by_name
  }

  def self.searchable(organisations, service: nil)
    motifs = Motif
      .reservable_online
      .active
      .joins(:organisation, :plage_ouvertures)
      .where(organisation_id: organisations.pluck(:id))
    motifs = motifs.where(service_id: service.id) if service
    motifs
  end

  def soft_delete
    rdvs.any? ? update_attribute(:deleted_at, Time.zone.now) : destroy
  end

  def service_name
    service.name
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
    for_secretariat ? [service, Service.secretariat] : [service]
  end

  def secretariat?
    for_secretariat?
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
