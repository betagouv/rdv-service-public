class Rdv < ApplicationRecord
  belongs_to :organisation
  belongs_to :motif
  belongs_to :user

  validates :user, :organisation, :motif, :start_at, :duration_in_min, presence: true
  validates :max_users_limit, numericality: { greater_than_or_equal_to: 0 }, allow_nil: true
  
  scope :active, -> { where(cancelled_at: nil) }

  def end_at
    start_at + duration_in_min.minutes
  end

  def cancelled?
    cancelled_at.present?
  end

  def to_step_params
    {
      organisation: organisation,
      motif: motif,
      duration_in_min: duration_in_min,
      start_at: start_at,
      max_users_limit: max_users_limit,
      user: user,
    }
  end
end
