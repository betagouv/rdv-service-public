module Participation::Creatable
  extend ActiveSupport::Concern

  def create_and_notify!(author)
    Participation.transaction do
      empty_rdv_from_relatives
      save!
      notify_create!(author)
    end
  end

  def participation_token
    # For user invited with tokens, nil default for not invited users
    @notifier&.participations_tokens_by_user_id&.fetch(user.id, nil)
  end

  private

  def empty_rdv_from_relatives
    # Empty self_and_relatives participations (at the moment, only one member by family), no callbacks, no notifications
    rdv.participations.where(user: user.self_and_relatives_and_responsible).delete_all
    rdv.participations.where(user: user.responsible&.self_and_relatives_and_responsible).delete_all
  end

  def notify_create!(author)
    # We pass an empty array if notifications are disabled to avoid notifying other users
    user_to_notify = send_lifecycle_notifications? ? [user] : []

    @notifier = Notifiers::RdvCreated.new(rdv, author, user_to_notify)
    @notifier.perform
  end
end
