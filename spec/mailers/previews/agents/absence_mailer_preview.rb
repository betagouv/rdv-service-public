# frozen_string_literal: true

class Agents::AbsenceMailerPreview < ActionMailer::Preview
  delegate :absence_created, :absence_updated, :absence_destroyed, to: :absence_mailer

  private

  def absence_mailer
    Agents::AbsenceMailer.with(absence: Absence.last)
  end
end
