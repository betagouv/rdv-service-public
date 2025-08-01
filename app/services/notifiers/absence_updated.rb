class Notifiers::AbsenceUpdated < Notifiers::AbsenceBase
  private

  def notify
    Agents::AbsenceMailer.with(absence: @absence).absence_updated.deliver_later
  end
end
