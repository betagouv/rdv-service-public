# frozen_string_literal: true

class Agents::AbsenceMailer < ApplicationMailer
  def absence_created(absence_payload)
    send_mail(absence_payload)
  end

  def absence_updated(absence_payload)
    send_mail(absence_payload)
  end

  def absence_destroyed(absence_payload)
    send_mail(absence_payload)
  end

  private

  def send_mail(absence_payload)
    self.ics_payload = absence_payload

    mail(
      from: "secretariat-auto@rdv-solidarites.fr",
      to: absence_payload[:agent_email],
      subject: "#{BRAND} - #{absence_payload[:title]}"
    )
  end
end
