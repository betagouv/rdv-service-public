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

  def rdv_user_token(user_id)
    @rdv_users_tokens_by_user_id&.fetch(user_id, nil)
  end

  def notify!(author, previous_participations)
    @rdv_users_tokens_by_user_id = {}
    if rdv_cancelled?
      file_attentes.destroy_all
      @rdv_users_tokens_by_user_id = Notifiers::RdvCancelled.perform_with(self, author)
    end

    if rdv_status_reloaded_from_cancelled?
      @rdv_users_tokens_by_user_id = Notifiers::RdvCreated.perform_with(self, author)
    end

    if starts_at_changed? || lieu_changed?
      @rdv_users_tokens_by_user_id = Notifiers::RdvUpdated.perform_with(self, author)
    end

    if collectif?
      @rdv_users_tokens_by_user_id = Notifiers::RdvCollectifParticipations.perform_with(self, author, previous_participations)
    end

    # we re-enable the webhooks that we deactivated during the notification process
    self.skip_webhooks = false
  end

  def rdv_status_reloaded_from_cancelled?
    status_previously_was.in?(%w[revoked excused]) && status == "unknown"
  end

  def lieu_changed?
    # Rappel :
    # - si le motif du RDV est de type `public_office`, le lieu est forcément renseigné, sinon il est forcément nil
    # - il est impossible de changer le motif d'un RDV
    return false unless lieu

    previous_changes["lieu_id"].present? || lieu.previous_changes.keys.include?("name") || lieu.previous_changes.keys.include?("address")
  end

  def rdv_cancelled?
    previous_changes["status"]&.last.in? %w[excused revoked noshow]
  end

  def starts_at_changed?
    previous_changes["starts_at"].present?
  end
end
