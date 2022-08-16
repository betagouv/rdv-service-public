# frozen_string_literal: true

class Notifiers::RdvCollectifParticipations < ::BaseService
  def initialize(rdv, author, previous_participations)
    @rdv = rdv
    @author = author
    @previous_participations = previous_participations
  end

  def perform
    return if @rdv.starts_at < Time.zone.now

    # FIXME: this is not ideal but it's the simplest workaround to avoid notifying the agent
    rdv_created = Notifiers::RdvCreated.new(@rdv, @author, new_participants)
    rdv_created_invitation_tokens = rdv_created.generate_invitation_tokens
    rdv_created.notify_users_by_mail
    rdv_created.notify_users_by_sms

    rdv_cancelled = Notifiers::RdvCancelled.new(@rdv, @author, removed_participants_with_lifecycle_notifications)
    # we don't generate token in this case since the user won't be linked to the rdv
    rdv_cancelled.notify_users_by_mail
    rdv_cancelled.notify_users_by_sms

    rdv_created_invitation_tokens
  end

  private

  def new_participants
    User.where(id: current_participations.select(&:send_lifecycle_notifications).map(&:user_id) - @previous_participations.map(&:user_id))
  end

  def removed_participants_with_lifecycle_notifications
    User.where(id: @previous_participations.select(&:send_lifecycle_notifications).map(&:user_id) - current_participations.map(&:user_id))
  end

  def current_participations
    @rdv.rdvs_users
  end
end
