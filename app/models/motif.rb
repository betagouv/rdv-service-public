class Motif < ApplicationRecord
  belongs_to :organisation
  belongs_to :service
  has_many :rdvs, dependent: :restrict_with_exception
  has_and_belongs_to_many :plage_ouvertures, -> { distinct }

  validates :name, presence: true, uniqueness: { scope: :organisation }
  validates :color, :service, :default_duration_in_min, :min_booking_delay, :max_booking_delay, presence: true
  validates :min_booking_delay, numericality: { greater_than_or_equal_to: 30.minutes, less_than_or_equal_to: 1.year.minutes }
  validates :max_booking_delay, numericality: { greater_than_or_equal_to: 30.minutes, less_than_or_equal_to: 1.year.minutes }
  validate :booking_delay_validation
  validate :not_associated_with_secretariat

  scope :active, -> { where(deleted_at: nil) }
  scope :online, -> { where(online: true) }
  scope :by_phone, -> { where(by_phone: true) }
  scope :available_motifs, lambda { |agent|
    available_motifs = agent.service.secretariat? ? by_phone : where(service: agent.service)
    available_motifs.active.order(Arel.sql('LOWER(name)'))
  }

  def soft_delete
    rdvs.any? ? update_attribute(:deleted_at, Time.zone.now) : destroy
  end

  def service_name
    service.name
  end

  def self.grouped_by_service_for_departement(departement)
    Motif.online
         .active
         .joins(:organisation, :plage_ouvertures)
         .where(organisations: { departement: departement })
         .includes(:service)
         .uniq
         .group_by { |m| m.service.name }
  end

  def name_with_badge
    label = name
    label = "#{label} <span class='badge badge-danger'>En ligne</span>" if online
    label = "#{label} <span class='badge badge-info'>Par tél.</span>" if by_phone
    label.html_safe
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
