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

  # Attributes
  auto_strip_attributes :title

  # Relations
  belongs_to :agent
  belongs_to :organisation

  # Through relations
  has_many :webhook_endpoints, through: :organisation

  # Validation
  validates :first_day, :title, presence: true
  validate :ends_at_should_be_after_starts_at
  validate :no_recurrence_for_absence_for_several_days
  validate :date_is_realistic

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

  # Ce check a été ajouté pour éviter d'inexplicables saisies
  # accidentelles, par exemple 1922 au lieu de 2022.
  # Voir : https://github.com/betagouv/rdv-solidarites.fr/issues/2914
  def date_is_realistic
    return unless first_day

    if first_day > 5.years.from_now
      errors.add(:first_day, "est plus de 5 and dans le futur, est-ce une erreur ?")
    end

    if first_day.year < 2018
      errors.add(:first_day, "est loin dans le passé, est-ce une erreur ?")
    end
  end
end
