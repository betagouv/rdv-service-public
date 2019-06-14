class Rdv < ApplicationRecord
  belongs_to :organisation

  def end_at
    start_at + duration_in_min.minutes
  end

  def cancelled?
    cancelled_at.present?
  end
end
