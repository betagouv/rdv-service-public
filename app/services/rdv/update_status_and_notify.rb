class Rdv::UpdateStatusAndNotify
  def initialize(rdv, author, status:)
    @rdv = rdv
    @author = author
    @status = status
  end

  def perform
    @rdv.update_status_and_notify(@author, status: @status)
  end
end
