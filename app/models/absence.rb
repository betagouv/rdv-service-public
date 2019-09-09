class Absence < ApplicationRecord
  belongs_to :pro
  belongs_to :organisation

  validates :starts_at, :ends_at, :pro, :organisation, presence: true
  validate :ends_at_should_be_after_starts_at

  default_scope -> { order(starts_at: :desc) }
  scope :a_venir, -> { where("starts_at > ?", Time.zone.now) }
  scope :passees, -> { where("ends_at < ?", Time.zone.now) }
  scope :en_cours, -> { where("starts_at <= ? AND ? <= ends_at", Time.zone.now, Time.zone.now) }

  def title_or_default
    title.present? ? title : "Absence"
  end

  private

  def ends_at_should_be_after_starts_at
    errors.add(:ends_at, "doit être après la date de commencement.") if starts_at.present? && ends_at.present? && starts_at >= ends_at
  end
end
