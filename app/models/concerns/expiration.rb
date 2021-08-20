# frozen_string_literal: true

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
    (recurrence.nil? && first_day < Time.zone.today) ||
      (recurrence.present? && recurrence.to_hash[:until].present? && recurrence.to_hash[:until].to_date < Time.zone.today)
  end

  def refresh_expired_cached
    update_column(:expired_cached, expired?)
  end
end
