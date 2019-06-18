class Rdv < ApplicationRecord
  belongs_to :organisation
  belongs_to :evenement_type
  belongs_to :user

  validates :user, :organisation, :evenement_type, :start_at, :duration_in_min, presence: true

  def end_at
    start_at + duration_in_min.minutes
  end

  def cancelled?
    cancelled_at.present?
  end

  def to_step_params
    {
      organisation: organisation,
      evenement_type: evenement_type,
      duration_in_min: duration_in_min,
      start_at: start_at,
      user: user,
    }
  end
end
