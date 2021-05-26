# frozen_string_literal: true

class Agents::AbsenceMailerPreview < ActionMailer::Preview
  def absence_created
    absence = Absence.last
    Agents::AbsenceMailer.absence_created(Admin::Ics::Absence.create_payload(absence))
  end

  def absence_updated
    absence = Absence.last
    Agents::AbsenceMailer.absence_updated(Admin::Ics::Absence.create_payload(absence))
  end

  def absence_destroyed
    absence = Absence.last
    Agents::AbsenceMailer.absence_destroyed(Admin::Ics::Absence.create_payload(absence))
  end
end
