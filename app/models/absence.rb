class Absence < ApplicationRecord
  self.ignored_columns += %w[caldav_url]

  # Mixins
  has_paper_trail
  include WebhookDeliverable
  include RecurrenceConcern
  include IcsPayloads::Absence
  include Expiration

  # Attributes
  auto_strip_attributes :title

  # Relations
  belongs_to :agent
  has_many :external_references, as: :item, dependent: :destroy

  # Through relations
  def webhook_endpoints
    WebhookEndpoint.where(organisation: agent.organisations)
  end

  # Validation
  validates :first_day, :title, presence: true
  validate :ends_at_must_be_after_starts_at, unless: :recurring?
  validate :end_time_must_be_after_start_time, if: :recurring?
  validate :no_recurrence_for_absence_for_several_days
  validates :first_day, realistic_date: true
  validates :end_day, realistic_date: true
  validates :recurrence_ends_at, realistic_date: true

  # Hooks
  before_validation :set_end_day
  after_commit do
    [agent_id, agent_id_was].uniq.each do |agent_id|
      AgendaChannel.broadcast_to(agent_id, model: "Absence")
    end
  end

  # Scopes
  scope :by_starts_at, ->(direction = :desc) { order(first_day: direction, start_time: direction) }
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
    "absence_#{id}@#{IcalFormatters::Ics::ICS_UID_SUFFIX}"
  end

  def ics_attachment_filename
    "absence-#{title.parameterize}-#{starts_at.to_s.parameterize}.ics"
  end

  private

  def set_end_day
    return unless end_day.nil?

    self.end_day = first_day
  end

  def ends_at_must_be_after_starts_at
    return if starts_at.blank? || ends_at.blank?

    errors.add(:end_time, :must_be_after_start_time) if starts_at >= ends_at
  end

  def no_recurrence_for_absence_for_several_days
    return if recurrence.blank? || end_day.blank? || first_day == end_day

    errors.add(:recurrence, "pas possible avec une indisponibilité de plusieurs jours")
  end
end
