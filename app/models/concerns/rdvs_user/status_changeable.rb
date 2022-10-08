# frozen_string_literal: true

module RdvsUser::StatusChangeable
  extend ActiveSupport::Concern

  def change_status(author, status)
    return if self.status == status

    RdvsUser.transaction do
      notify!(author) if update(status:)
    end
  end

  def notify!(author)
    if status == "excused"
      Notifiers::RdvCancelled.perform_with(rdv, author, [user])
    end
    # TODO cases...
  end
end
