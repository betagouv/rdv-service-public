# frozen_string_literal: true

module Rdv::StatusChangeable
  extend ActiveSupport::Concern

  def change_status(author, status)
    Rdv.transaction do
      # Consequences on participations with RDV.status changes :
      if update(status:)
        case status
        when "unknown"
          # Setting to unknown means resetting the rdv status by agents and reset ALL participants statuses
          # All participants get a creation notification (like a new rdv)
          rdvs_users.map { _1.change_status(author, status) }
        # Others participations changes are not applied on already revoked or excused participants (not_cancelled)
        when "excused"
          # Collective rdv cannot be globally excused
          # On non collectives rdv all paricipants are excused
          rdvs_users.not_cancelled.map { _1.change_status(author, status) unless collectif? }
        when "revoked"
          # When rdv status is revoked, all participants are revoked (and get a cancellation notification)
          rdvs_users.not_cancelled.map { _1.change_status(author, status) }
        when "seen", "noswhow"
          # When rdv status is seen or noshow, all unknown statuses are changed
          rdvs_users.not_cancelled.where(status: "unknown").map { _1.change_status(author, status) }
        end
      end
    end
  end
end
