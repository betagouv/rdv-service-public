module RdvUpdater
  def self.update(rdv, rdv_params)
    rdv.updated_at = Time.zone.now
    # TODO: replace this manual touch. It forces creating a version when an
    # agent or a user is removed from the RDV. the touch: true option on the
    # association does not do it for some reason I could not figure out

    if rdv_params[:status].present?
      rdv_params[:cancelled_at] = cancel_status?(rdv_params[:status]) ? Time.zone.now : nil
    end

    return false unless rdv.update(rdv_params)

    if rdv_params[:status] == "excused"
      Notifications::Rdv::RdvCancelledByAgentService.perform_with(rdv)
      "Le rendez-vous a été annulé."
    else
      "Le rendez-vous a été modifié."
    end
  end

  def self.cancel_status?(status)
    %w[excused notexcused].include?(status)
  end
end
