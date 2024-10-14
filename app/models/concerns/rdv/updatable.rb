module Rdv::Updatable
  extend ActiveSupport::Concern

  def update_and_notify(author, attributes)
    @old_agent_ids = agent_ids.to_a
    assign_attributes(attributes)
    save_and_notify(author)
  end

  def save_and_notify(author)
    Rdv.transaction do
      self.updated_at = Time.zone.now
      previous_participations = participations.select(&:persisted?)
      remove_duplicate_participations

      set_created_by_for_new_participations(author)

      if status_changed? && valid?
        self.cancelled_at = status.in?(%w[excused revoked noshow]) ? Time.zone.now : nil
        change_participation_statuses
        # Reload is needed after .persisted? method call.
        participations.reload
      end

      if save
        notify!(author, previous_participations)
        true
      else
        false
      end
    end
  end

  def participation_token(user_id)
    # For user invited with tokens, nil default for not invited users
    @notifier&.participations_tokens_by_user_id&.fetch(user_id, nil)
  end

  def new_cancelled_notifier(author, previous_participations)
    # Don't notify RDV cancellation to users that had previously cancelled their individual participation
    available_users_for_notif = previous_participations.select(&:not_cancelled?).map(&:user)
    Notifiers::RdvCancelled.new(self, author, available_users_for_notif)
  end

  def rdv_status_reloaded_from_cancelled?
    status_previously_was.in?(Rdv::CANCELLED_STATUSES) && status == "unknown"
  end

  def lieu_changed?
    # Rappel :
    # - si le motif du RDV est de type `public_office`, le lieu est forcément renseigné, sinon il est forcément nil
    # - il est impossible de changer le motif d'un RDV
    return false unless lieu

    previous_changes["lieu_id"].present? || lieu.previous_changes.keys.include?("name") || lieu.previous_changes.keys.include?("address")
  end

  def rdv_cancelled?
    previous_changes["status"]&.last.in?(Rdv::CANCELLED_STATUSES)
  end

  def starts_at_changed?
    previous_changes["starts_at"].present?
  end

  def rdv_updated?
    # TODO : How to pass the list of old agents from Admin::EditRdvForm to Updatable ?
    # TODO : add agents_changed?
    starts_at_changed? || lieu_changed?
  end

  private

  def remove_duplicate_participations
    existing_participations = Participation.where(rdv_id: id).to_a # pour éviter une requête N+1

    participations.each do |participation|
      existing_participation = existing_participations.find { |p| p.user_id == participation.user_id }
      next unless existing_participation

      participation.id = existing_participation.id
    end.uniq!
  end

  def notify!(author, previous_participations)
    if rdv_cancelled?
      file_attentes.destroy_all
      @notifier = new_cancelled_notifier(author, previous_participations)
    elsif rdv_status_reloaded_from_cancelled?
      @notifier = Notifiers::RdvCreated.new(self, author)
    elsif rdv_updated?
      @notifier = Notifiers::RdvUpdated.new(self, author, old_agent_ids: @old_agent_ids)
    end

    @notifier&.perform

    if collectif? && previous_participations.sort != participations.sort
      Notifiers::RdvCollectifParticipations.perform_with(self, author, previous_participations)
    end
  end

  def change_participation_statuses
    case status
    when "unknown"
      # Setting to unknown means resetting the rdv status by agents and reset ALL participations statuses
      participations.each { _1.update!(status: status) }
    when "revoked", "excused"
      # When rdv status is revoked/excused, not cancelled participations are updated to revoked/excused
      # Collectives RDV status cannot be excused (validations)
      participations.not_cancelled.each { _1.update!(status: status) }
    when "seen", "noshow"
      # When rdv status is seen/noshow, unknowns participations statuses are updated to seen/noshow
      # Collectives RDV status cannot be noshow (validations)
      participations.unknown.each { _1.update!(status: status) }
    end
  end

  def set_created_by_for_new_participations(author) # rubocop:disable Naming/AccessorMethodName
    participations.select(&:new_record?).each { |participation| participation.created_by = author }
  end
end
