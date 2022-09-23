# frozen_string_literal: true

module Rdv::Updatable
  extend ActiveSupport::Concern

  def update_with_notifs(author, attributes)
    assign_attributes(attributes)
    save_with_notifs(author)
  end

  def save_with_notifs(author)
    Rdv.transaction do
      self.updated_at = Time.zone.now
      self.cancelled_at = status.in?(%w[excused revoked noshow]) ? Time.zone.now : nil if status_changed?

      previous_participations = rdvs_users.select(&:persisted?)

      if save
        rdv_users_tokens_by_user_id = notify!(author, previous_participations)
        Result.new(success: true, rdv_users_tokens_by_user_id: rdv_users_tokens_by_user_id)
      else
        Result.new(success: false)
      end
    end
  end

  def notify!(author, previous_participations)
    rdv_users_tokens_by_user_id = {}
    if rdv_cancelled?
      file_attentes.destroy_all
      rdv_users_tokens_by_user_id = Notifiers::RdvCancelled.perform_with(self, author)
    end

    if rdv_status_reloaded_from_cancelled?
      rdv_users_tokens_by_user_id = Notifiers::RdvCreated.perform_with(self, author)
    end

    if starts_at_change? || lieu_change?
      rdv_users_tokens_by_user_id = Notifiers::RdvUpdated.perform_with(self, author)
    end

    if collectif?
      rdv_users_tokens_by_user_id = Notifiers::RdvCollectifParticipations.perform_with(self, author, previous_participations)
    end

    rdv_users_tokens_by_user_id
  end

  def rdv_status_reloaded_from_cancelled?
    status_previously_was.in?(%w[revoked excused]) && status == "unknown"
  end

  def lieu_change?
    # Rappel :
    # - si le motif du RDV est de type `public_office`, le lieu est forcément renseigné, sinon il est forcément nil
    # - il est impossible de changer le motif d'un RDV
    return false unless lieu

    previous_changes["lieu_id"].present? || lieu.previous_changes.keys.include?("name") || lieu.previous_changes.keys.include?("address")
  end

  def rdv_cancelled?
    previous_changes["status"]&.last.in? %w[excused revoked noshow]
  end

  def starts_at_change?
    previous_changes["starts_at"].present?
  end

  class Result
    attr_reader :success, :rdv_users_tokens_by_user_id
    alias success? success

    def initialize(success:, rdv_users_tokens_by_user_id: {})
      @success = success
      @rdv_users_tokens_by_user_id = rdv_users_tokens_by_user_id
    end
  end
end
