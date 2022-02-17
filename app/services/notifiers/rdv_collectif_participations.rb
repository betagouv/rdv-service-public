# frozen_string_literal: true

class Notifiers::RdvCollectifParticipations < ::BaseService
  def initialize(rdv, author, previous_participant_ids)
    @rdv = rdv
    @author = author
    @previous_participant_ids = previous_participant_ids
  end

  def perform
    Notifiers::RdvCreated.perform_with(@rdv, @author, new_participants)
    Notifiers::RdvCancelled.perform_with(@rdv, @author, deleted_participants)
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
