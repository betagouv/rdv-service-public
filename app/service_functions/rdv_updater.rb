# frozen_string_literal: true

module RdvUpdater
  class << self
    def update(author, rdv, rdv_params)
      # Explicitly touch the Rdv to make sure a new Version is saved on paper_trail
      # This may be needed when changing associations, when adding/removing an agent or a user.
      rdv.updated_at = Time.zone.now

      # Set/reset cancelled_at when the status changes
      if rdv_params[:status].present?
        rdv_params[:cancelled_at] = rdv_params[:status].in?(%w[excused revoked notexcused]) ? Time.zone.now : nil
      end

      result = rdv.update(rdv_params)

      # Send relevant notifications (cancellation and date update)
      if result
        if rdv.previous_changes["status"]&.last.in? %w[excused revoked notexcused]
          # Also destroy the file_attentes
          rdv.file_attentes.destroy_all
          Notifications::Rdv::RdvCancelledService.perform_with(rdv, author)
        end

        if rdv.previous_changes["starts_at"].present?
          Notifications::Rdv::RdvDateUpdatedService.perform_with(rdv, author)
        end
      end
      result
    end
  end
end
