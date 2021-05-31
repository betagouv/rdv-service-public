# frozen_string_literal: true

module RdvUpdater
  class << self
    def update(author, rdv, rdv_params)
      rdv.updated_at = Time.zone.now
      # TODO: replace this manual touch. It forces creating a version when an
      # agent or a user is removed from the RDV. the touch: true option on the
      # association does not do it for some reason I could not figure out

      if rdv_params[:status].present?
        rdv_params[:cancelled_at] = rdv_params[:status].in?(%w[excused notexcused]) ? Time.zone.now : nil
      end

      result = rdv.update(rdv_params)
      send_relevant_notifications(author, rdv, rdv_params) if result
      result
    end

    def send_relevant_notifications(author, rdv, rdv_params)
      notify_cancellation_to_agent(author, rdv) if rdv_params[:status].in? %w[excused notexcused]
      notify_cancellation_to_user(author, rdv) if rdv_params[:status] == "excused"
      notify_starts_at_change(author, rdv) if rdv_params[:starts_at].present?
    end

    def notify_cancellation_to_agent(author, rdv)
      rdv.file_attentes.destroy_all
      Notifications::Rdv::RdvCancelledService.perform_with(rdv, author)
    end

    def notify_cancellation_to_user(author, rdv)
      case author
      when Agent
        Notifications::Rdv::RdvCancelledByAgent.perform_with(rdv, author)
      when User
        Notifications::Rdv::RdvCancelledByUser.perform_with(rdv, author)
      end
    end

    def notify_starts_at_change(author, rdv)
      Notifications::Rdv::RdvDateUpdatedService.perform_with(rdv, author)
    end
  end
end
