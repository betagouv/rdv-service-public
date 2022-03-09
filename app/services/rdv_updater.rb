# frozen_string_literal: true

module RdvUpdater
  class << self
    def update(author, rdv, rdv_params)
      # Explicitly touch the Rdv to make sure a new Version is saved on paper_trail
      # This may be needed when changing associations, when adding/removing an agent or a user.
      rdv.updated_at = Time.zone.now

      # Set/reset cancelled_at when the status changes
      if rdv_params[:status].present?
        rdv_params[:cancelled_at] = rdv_params[:status].in?(%w[excused revoked noshow]) ? Time.zone.now : nil
      end

      success = rdv.update(rdv_params)

      # Send relevant notifications (cancellation and date update)
      if success
        rdv.file_attentes.destroy_all if rdv.previous_changes["status"]&.last.in? %w[excused revoked noshow]
        # Also destroy the file_attentes

        rdv_users_tokens_by_user_id = notifier_for_rdv(rdv)&.perform_with(rdv, author)
      end

      OpenStruct.new(
        { success?: success }
        .merge(success ? { rdv_users_tokens_by_user_id: rdv_users_tokens_by_user_id } : {})
      )
    end

    def notifier_for_rdv(rdv)
      if rdv.previous_changes["status"]&.last.in? %w[excused revoked noshow]
        Notifiers::RdvCancelled
      elsif rdv.previous_changes["starts_at"].present?
        Notifiers::RdvDateUpdated
      end
    end
  end
end
