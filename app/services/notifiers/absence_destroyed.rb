class Notifiers::AbsenceDestroyed < Notifiers::AbsenceBase
  private

  def notify
    # On passe l'absence au job sous forme sérialisée puisqu'elle n'existe plus en base.
    Agents::AbsenceMailer.with(absence: Absence.serialize_for_active_job(@absence)).absence_destroyed.deliver_later
  end
end
