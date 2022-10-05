# frozen_string_literal: true

module RdvsUser::Notificationable
  extend ActiveSupport::Concern

  def update_and_notify(author, attributes)
    assign_attributes(attributes)
    return unless status_changed?
    @rdv = rdv
    save_and_notify(author)
  end

  def save_and_notify(author)
    RdvsUser.transaction do
      if save
        notify!(author)
        true
      else
        false
      end
    end
  end

  def notify!(author)
    if status == 'excused'
      Notifiers::RdvCancelled.perform_with(@rdv, author, [user])
    end
  end
end
