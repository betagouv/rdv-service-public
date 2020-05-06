class CancelRdvByAgentService
  def initialize(rdv)
    @rdv = rdv
  end

  def perform
    @rdv.update!(status: :excused, cancelled_at: Time.now)
    Notifications::Rdv::RdvCancelledByAgentService.perform_with(@rdv)
  end
end
