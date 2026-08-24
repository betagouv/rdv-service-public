class Notifiers::Agent::Absence
  def initialize(absence)
    @absence = absence
  end

  def created!
    perform(mailer.absence_created)
  end

  def updated!
    perform(mailer.absence_updated)
  end

  def destroyed!
    # On passe l'absence au job sous forme sérialisée puisqu'elle n'existe plus en base.
    perform(Agents::AbsenceMailer.with(absence: Absence.serialize_for_active_job(@absence)).absence_destroyed)
  end

  private

  def perform(mailer_action)
    mailer_action.deliver_later if agent_notifiable?
  end

  def mailer
    Agents::AbsenceMailer.with(absence: @absence)
  end

  def agent_notifiable?
    @absence.agent&.email.present? && @absence.agent.absence_notification_level == "all"
  end
end
