module Rdv::StatusChangeable
  extend ActiveSupport::Concern

  def change_status(author, status:)
    Rdv.transaction do
      if update(status: status)
        case status
        when "unknown"
          rdvs_users.change_status(author, status:)
        when "excused"
          rdvs_users.not_cancelled.change_status(author, status:) unless collectif?
        when "revoked"
          rdvs_users.not_cancelled.change_status(author, status:)
        when "seen", "noswhow"
          rdvs_users.not_cancelled.where(status: "unknown").change_status(author, status:)
        end
      end
    end
  end
end
