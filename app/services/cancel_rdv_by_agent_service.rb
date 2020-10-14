class CancelRdvByAgentService
  def initialize(rdv)
    @rdv = rdv
  end

  def perform
    @rdv.cancel!
    Notifications::Rdv::RdvCancelledByAgentService.perform_with(@rdv)
  end
end
