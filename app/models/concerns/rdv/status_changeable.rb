# frozen_string_literal: true

module Rdv::StatusChangeable
  extend ActiveSupport::Concern

  def change_status(author, status)
    Rdv.transaction do
      # Consequences on participations with RDV.status changes :
      if update(status: status)
        case status
        when "unknown"
          # Setting to unknown means resetting the rdv status by agents and reset ALL participants statuses
          notify!(author)
          rdvs_users.update(status: status)
        when "excused"
          # Collective rdv cannot be globally excused (todordvc test)
          return if collectif?

          # On non collectives rdv all participants are excused
          notify!(author)
          rdvs_users.not_cancelled.update(status: status)
        when "revoked"
          # When rdv status is revoked, all participants are revoked
          notify!(author)
          rdvs_users.not_cancelled.update(status: status)
        when "seen", "noswhow"
          # When rdv status is seen or noshow, all unknown statuses are changed
          rdvs_users.not_cancelled.where(status: "unknown").update(status: status)
        end
        true
      else
        false
      end
    end
  end

  def notify!(author)
    if rdv_cancelled?
      @rdv_users_tokens_by_user_id = Notifiers::RdvCancelled.perform_with(self, author)
    end
    if rdv_status_reloaded_from_cancelled?
      @rdv_users_tokens_by_user_id = Notifiers::RdvCreated.perform_with(self, author)
    end
  end

  def rdv_cancelled?
    previous_changes["status"]&.last.in? %w[excused revoked]
  end

  def rdv_status_reloaded_from_cancelled?
    status_previously_was.in?(%w[revoked excused]) && status == "unknown"
  end

  def rdv_user_token(user_id)
    @rdv_users_tokens_by_user_id&.fetch(user_id, nil)
  end
end
