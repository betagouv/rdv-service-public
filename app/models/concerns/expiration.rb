# Pour fonctionner, ce module utilise les champs
#
# - `expired_cached (bool)`
# - `recurrence (Montrose-formatted string)`
#
# Pour la récurrence, voir le format de sérialisation de la gem [Montrose](https://rossta.net/montrose/)
#
module Expiration
  extend ActiveSupport::Concern

  included do
    after_save :refresh_expired_cached

    scope :expired, -> { where(expired_cached: true) }
    scope :not_expired, -> { where.not(expired_cached: true) }
  end

  def expired?
    return false if absence_end_day_in_future? || first_day_in_future? || recurrence_ends_at_in_future?

    true
  end

  def refresh_expired_cached
    update_column(:expired_cached, expired?)
  end

  def absence_end_day_in_future?
    schedule.nil? && instance_of?(Absence) && end_day >= Time.zone.today
  end

  def first_day_in_future?
    schedule.nil? && first_day >= Time.zone.today
  end

  def recurrence_ends_at_in_future?
    schedule.present? && (recurrence_ends_at.nil? || recurrence_ends_at >= Time.zone.today)
  end
end
