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
    attachments[absence_payload[:name]] = {
      mime_type: "text/calendar",
      content: Admin::Ics::Absence.to_ical(absence_payload),
      encoding: "8bit" # fixes encoding issues in ICS
    }

    m = mail(
      from: "secretariat-auto@rdv-solidarites.fr",
      to: absence_payload[:agent_email],
      subject: "#{BRAND} - #{absence_payload[:title]}"
    )
    m.add_part(
      Mail::Part.new do
        content_type "text/calendar; method=REQUEST; charset=utf-8"
        body Base64.encode64(Admin::Ics::Absence.to_ical(absence_payload))
        content_transfer_encoding "base64"
        # quoted-printable would be more adapted but there seems to be an encoding problem with extra =0D
      end
    )
    m
  end
end
