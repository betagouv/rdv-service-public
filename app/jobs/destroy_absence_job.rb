class DestroyAbsenceJob < ApplicationJob
  def perform(absence_id)
    absence = Absence.find_by(id: absence_id)
    return unless absence

    if absence.agent.absence_notification_level == "all"
      Absence.transaction do
        Agents::AbsenceMailer.with(absence: absence).absence_destroyed.deliver_now
        absence.destroy!
      end
    else
      absence.destroy!
    end
  end
end
