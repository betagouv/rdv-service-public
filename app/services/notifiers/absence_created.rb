class Notifiers::AbsenceCreated < Notifiers::AbsenceBase
  private

  def notify
    Agents::AbsenceMailer.with(absence: @absence).absence_created.deliver_later
  end
end
