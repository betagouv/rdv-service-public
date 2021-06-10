# frozen_string_literal: true

class Agents::AbsenceMailerPreview < ActionMailer::Preview
  def absence_created
    absence = Absence.last
    Agents::AbsenceMailer.absence_created(absence.payload(:create))
  end

  def absence_updated
    absence = Absence.last
    Agents::AbsenceMailer.absence_updated(absence.payload(:update))
  end

  def absence_destroyed
    absence = Absence.last
    Agents::AbsenceMailer.absence_destroyed(absence.payload(:destroy))
  end
end
