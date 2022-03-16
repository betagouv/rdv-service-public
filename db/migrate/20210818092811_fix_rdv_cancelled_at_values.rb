# frozen_string_literal: true

class FixRdvCancelledAtValues < ActiveRecord::Migration[6.0]
  def change
    up_only do
      # These rdvs should not have a cancelled_at value
      rdvs_wrongly_cancelled = Rdv.where(status: %w[unknown waiting seen])
        .where.not(cancelled_at: nil)
      Rails.logger.info "Clearing cancelled_at of #{rdvs_wrongly_cancelled.count} rdvs…"
      rdvs_wrongly_cancelled.update_all(cancelled_at: nil)
      Rails.logger.info "Done"

      # These rdvs should have a cancelled_at value
      rdvs_wrongly_not_cancelled = Rdv.where(status: %w[excused revoked noshow])
        .where(cancelled_at: nil)
      Rails.logger.info "Setting cancelled_at of #{rdvs_wrongly_not_cancelled.count} rdvs…"
      rdvs_wrongly_not_cancelled.update_all("cancelled_at = updated_at")
      Rails.logger.info "Done"
    end
  end
end
