class Notifiers::AbsenceBase < BaseService
  def initialize(absence)
    @absence = absence
  end

  def perform
    notify if agent_notifiable?
  end

  private

  def notify
    raise NotImplementedError, "Subclasses must implement the notify method"
  end

  def agent_notifiable?
    @absence.agent.email.present? && @absence.agent.absence_notification_level == "all"
  end
end
