class Absence < ApplicationRecord
  include RecurrenceConcern

  belongs_to :agent
  belongs_to :organisation

  before_validation :set_end_day
  validates :agent, :organisation, :end_day, presence: true
  validate :ends_at_should_be_after_starts_at

  default_scope -> { order(first_day: :desc, start_time: :desc) }

  def title_or_default
    title.present? ? title : "Absence"
  end

  def in_progress?
    starts_at.past? && ends_at.future?
  end

  private

  def set_end_day
    return unless end_day.nil?

    self.end_day = first_day
  end

  def ends_at_should_be_after_starts_at
    errors.add(:ends_time, "doit être après le début.") if starts_at >= ends_at
  end
end
