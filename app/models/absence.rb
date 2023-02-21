# frozen_string_literal: true

class Absence < ApplicationRecord
  # Mixins
  has_paper_trail
  include WebhookDeliverable
  include RecurrenceConcern
  include IcalHelpers::Ics
  include IcalHelpers::Rrule
  include Payloads::Absence
  include Expiration
  include EnsuresRealisticDate

  # Attributes
  auto_strip_attributes :title

  # Relations
  belongs_to :agent
  has_many :absences_organisations, dependent: :destroy

  # Through relations
  has_many :organisations, through: :absences_organisations

  # Validation
  validates :first_day, :title, presence: true
  validates :absences_organisations, presence: true, unless: :territory_wide
  validate :ends_at_should_be_after_starts_at
  validate :no_recurrence_for_absence_for_several_days

  # Hooks
  before_validation :set_end_day

  # Scopes
  scope :for_organisation, lambda { |org|
    joins(:absences_organisations)
      .where(territory_wide: false, absences_organisations: { organisation_id: org.id })
      .or(where(territory_wide: true))
  }
  scope :by_starts_at, -> { order(first_day: :desc, start_time: :desc) }
  scope :in_range, lambda { |range|
    return all if range.nil?

    not_recurring_start_in_range = where(recurrence: nil).where("first_day <= ?", range.end).where("end_day >= ?", range.begin)
    # This tsrange expression is indexed on absences
    recurring_in_range = where.not(recurrence: nil).where("tsrange(first_day, recurrence_ends_at, '[]') && tsrange(?, ?)", range.begin, range.end)

    not_recurring_start_in_range.or(recurring_in_range)
  }

  ## -

  def ical_uid
    "absence_#{id}@#{IcalHelpers::ICS_UID_SUFFIX}"
  end

  # remplace la jointure :
  # `has_many :webhook_endpoints, through: :organisation`
  # nécessaire depuis la création de la table de jointure entre les organisations et les absences
  def webhook_endpoints
    organisations.map(&:webhook_endpoints).flatten
  end

  private

  def set_end_day
    return unless end_day.nil?

    self.end_day = first_day
  end

  def ends_at_should_be_after_starts_at
    return if starts_at.blank? || ends_at.blank?

    errors.add(:ends_time, "doit être après le début.") if starts_at >= ends_at
  end

  def no_recurrence_for_absence_for_several_days
    return if recurrence.blank? || end_day.blank? || first_day == end_day

    errors.add(:recurrence, "pas possible avec une indisponibilité de plusieurs jours")
  end
end
