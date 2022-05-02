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

      previous_participant_ids = rdv.participants_with_life_cycle_notification_ids

      success = rdv.update(rdv_params)

      rdv_users_tokens_by_user_id = {}

      # Send relevant notifications (cancellation and date update)
      if success
        if rdv.previous_changes["status"]&.last.in? %w[excused revoked noshow]
          # Also destroy the file_attentes
          rdv.file_attentes.destroy_all

          rdv_users_tokens_by_user_id = Notifiers::RdvCancelled.perform_with(rdv, author)
        end

        if rdv.previous_changes["starts_at"].present?
          rdv_users_tokens_by_user_id = Notifiers::RdvDateUpdated.perform_with(rdv, author)
        end

        if rdv.collectif?
          rdv_users_tokens_by_user_id = Notifiers::RdvCollectifParticipations.perform_with(rdv, author, previous_participant_ids)
        end
      end

      Result.new(
        success: success,
        rdv_users_tokens_by_user_id: rdv_users_tokens_by_user_id
      )
    end
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
