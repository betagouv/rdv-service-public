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

  # Through relations
  def webhook_endpoints
    WebhookEndpoint.where(organisation: agent.organisations)
  end

  # Validation
  validates :first_day, :title, presence: true
  validate :ends_at_should_be_after_starts_at
  validate :no_recurrence_for_absence_for_several_days

  # Hooks
  before_validation :set_end_day

  # Scopes
  scope :by_starts_at, -> { order(first_day: :desc, start_time: :desc) }
  scope :in_range, lambda { |range|
    return all if range.nil?

    not_recurring_start_in_range = where(recurrence: nil).where("first_day <= ?", range.end).where("end_day >= ?", range.begin)
    # This tsrange expression is indexed on absences
    recurring_in_range = where.not(recurrence: nil).where("tsrange(first_day, recurrence_ends_at, '[]') && tsrange(?, ?)", range.begin, range.end)

    not_recurring_start_in_range.or(recurring_in_range)
  }

  # Delegations
  delegate :domain, to: :agent

  ## -

  def ical_uid
    "absence_#{id}@#{IcalHelpers::ICS_UID_SUFFIX}"
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
