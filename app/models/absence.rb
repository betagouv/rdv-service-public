class Absence < ApplicationRecord
  include WebhookDeliverable
  include RecurrenceConcern

  belongs_to :agent
  belongs_to :organisation

  has_many :webhook_endpoints, through: :organisation

  before_validation :set_end_day
  validates :agent, :organisation, :first_day, presence: true
  validate :ends_at_should_be_after_starts_at

  default_scope -> { order(first_day: :desc, start_time: :desc) }

  def title_or_default
    title.present? ? title : "Absence"
  end

  def in_progress?
    starts_at.past? && first_occurence_ends_at.future?
  end

  def ical_uid
    "absence_#{id}@#{BRAND}"
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
end
