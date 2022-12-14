# frozen_string_literal: true

module Rdv::Updatable
  extend ActiveSupport::Concern

  def update_and_notify(author, attributes)
    assign_attributes(attributes)
    save_and_notify(author)
  end

  def save_and_notify(author)
    Rdv.transaction do
      self.updated_at = Time.zone.now

      if status_changed?
        self.cancelled_at = status.in?(%w[excused revoked noshow]) ? Time.zone.now : nil
        change_participation_statuses(status)
      end

      previous_participations = rdvs_users.select(&:persisted?)

      if save
        notify!(author, previous_participations)
        true
      else
        false
      end
    end
  end

  def change_participation_statuses(status)
    # Consequences on participations with RDV.status changes :
    case status
    when "unknown"
      # Setting to unknown means resetting the rdv status by agents and reset ALL participants statuses
      rdvs_users.each { _1.update!(status: status) }
    when "excused"
      # Collective rdv cannot be globally excused
      unless collectif?
        # On non collectives rdv all participants are excused
        rdvs_users.not_cancelled.each { _1.update!(status: status) }
      end
    when "revoked"
      # When rdv status is revoked, all participants are revoked
      rdvs_users.not_cancelled.each { _1.update!(status: status) }
    when "seen", "noshow"
      # When rdv status is seen or noshow, all unknown statuses are changed
      rdvs_users.unknown.each { _1.update!(status: status) }
    end
  end

  def rdv_user_token(user_id)
    # For user invited with tokens, nil default for not invited users
    @notifier&.rdv_users_tokens_by_user_id&.fetch(user_id, nil)
  end

  def notify!(author, previous_participations)
    if rdv_cancelled?
      file_attentes.destroy_all
      @notifier = Notifiers::RdvCancelled.new(self, author)
    elsif rdv_status_reloaded_from_cancelled?
      @notifier = Notifiers::RdvCreated.new(self, author)
    elsif rdv_updated?
      @notifier = Notifiers::RdvUpdated.new(self, author)
    end

    @notifier&.perform

    if collectif? && previous_participations.sort != rdvs_users.sort
      Notifiers::RdvCollectifParticipations.perform_with(self, author, previous_participations)
    end
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
    starts_at_changed? || lieu_changed?
  end
end
