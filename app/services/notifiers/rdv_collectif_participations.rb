# frozen_string_literal: true

class Notifiers::RdvCollectifParticipations < ::BaseService
  def initialize(rdv, author, previous_participant_ids)
    @rdv = rdv
    @author = author
    @previous_participant_ids = previous_participant_ids
  end

  def perform
    return if @rdv.starts_at < Time.zone.now

    # FIXME: this is not ideal but it's the simplest workaround to avoid notifying the agent
    rdv_created = Notifiers::RdvCreated.new(@rdv, @author, new_participants)
    rdv_created.notify_users_by_mail
    rdv_created.notify_users_by_sms

    rdv_cancelled = Notifiers::RdvCancelled.new(@rdv, @author, deleted_participants)
    rdv_cancelled.notify_users_by_mail
    rdv_cancelled.notify_users_by_sms
  end

  private

  def new_participants
    @new_participants ||= User.where(id: (current_participant_ids - @previous_participant_ids))
  end

  def deleted_participants
    @deleted_participants ||= User.where(id: (@previous_participant_ids - current_participant_ids))
  end

  def current_participant_ids
    @rdv.participants_with_life_cycle_notification_ids
  end
end
