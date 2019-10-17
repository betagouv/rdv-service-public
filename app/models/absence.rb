class Absence < ApplicationRecord
  belongs_to :agent
  belongs_to :organisation

  validates :starts_at, :ends_at, :agent, :organisation, presence: true
  validate :ends_at_should_be_after_starts_at

  default_scope -> { order(starts_at: :desc) }

  scope :in_time_range, lambda { |time_range| where(starts_at: time_range).or(where(ends_at: time_range)).or(where("starts_at < ? AND ends_at > ?", time_range.begin, time_range.end)) }

  def title_or_default
    title.present? ? title : "Absence"
  end

  def in_progress?
    starts_at.past? && ends_at.future?
  end

  private

  def ends_at_should_be_after_starts_at
    errors.add(:ends_at, "doit être après la date de commencement.") if starts_at >= ends_at
  end
end
