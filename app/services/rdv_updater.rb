class RdvUpdater

  def initialize(rdv)
    @rdv = rdv
  end

  def update(rdv_params)
    @rdv.updated_at = Time.zone.now
    Notifications::Rdv::RdvCancelledByAgentService.perform_with(@rdv) if rdv_params[:status] == "excused"
    @rdv.update(rdv_params)
  end
end
