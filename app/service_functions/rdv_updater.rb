module RdvUpdater
  class << self
    def update(rdv, rdv_params)
      rdv.updated_at = Time.zone.now
      # TODO: replace this manual touch. It forces creating a version when an
      # agent or a user is removed from the RDV. the touch: true option on the
      # association does not do it for some reason I could not figure out

      if rdv_params[:status].present?
        rdv_params[:cancelled_at] = cancel_status?(rdv_params[:status]) ? Time.zone.now : nil
      end

      return false unless rdv.update(rdv_params)

      Notifications::Rdv::RdvCancelledByAgentService.perform_with(rdv) if rdv_params[:status] == "excused"
      true
    end

    private

    def cancel_status?(status)
      %w[excused notexcused].include?(status)
    end
  end
end
